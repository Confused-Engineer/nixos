# Proxmox VM, cloned from server-template, running OpenCloud (file
# sync/share) and OnlyOffice DocumentServer (in-browser office editing via
# WOPI). Both are native NixOS services — no podman containers on this
# host, same as attic. Users and groups come from the existing lldap
# instance on 10.87.6.10 (a different host, outside this config); OpenCloud
# logs in against it and reads its directory, nothing LDAP runs here.
# custom.virtualization.proxmox-vm and custom.virtualization.container-host
# still carry the shared disk/OS boilerplate (root-only SSH, disko root
# disk, auto-upgrade, growPartition, journald limits, etc.). This file only
# has what's actually specific to this host: the second data disk and the
# two services.
#
# TLS termination and the public hostnames are handled by Traefik outside
# this repo, the same as attic — this host only ever speaks plain HTTP on
# the LAN:
#   https://cloud.a5f.org   -> :9200  (OpenCloud proxy, the web UI)
#   https://office.a5f.org  -> :80    (OnlyOffice, via nginx)
# Change the two `*Url` bindings below if the hostnames differ.
#
# Secrets are NOT in this repo. Create these on the host before the
# services can start — templates with every key documented sit next to
# this file, and README.md "opencloud" has the exact steps:
#   /etc/onlyoffice/nonce.conf  <- onlyoffice-nonce.conf.example
#   /etc/opencloud.env          <- opencloud.env.example
{ config, pkgs, ... }:
let
  cloudUrl = "https://opencloud.a5f.org";
  officeUrl = "https://onlyoffice.a5f.org";

  # The existing lldap host. Plain ldap:// (lldap's LDAP port is unencrypted
  # by default); it's LAN-only traffic between two VMs.
  ldapUri = "ldap://10.87.6.10:3890";
  # Must match `ldap_base_dn` on that lldap instance.
  ldapBaseDn = "dc=a5f,dc=org";
  # Dedicated read-only bind account, created in the lldap UI and added to
  # the `lldap_strict_readonly` group — OpenCloud never writes to LDAP
  # (OC_LDAP_SERVER_WRITE_ENABLED=false below), so it doesn't need the
  # admin account. Its password goes in /etc/opencloud.env.
  ldapBindDn = "uid=read_only_admin,ou=people,${ldapBaseDn}";
in
{
  imports = [
    ./../../nixosModules
    ./../../nixosModules/virtualization/proxmox-vm.nix
  ];

  custom.virtualization.proxmox-vm.enable = true;
  custom.virtualization.container-host.enable = true;

  networking.hostName = "opencloud";
  networking.firewall.allowedTCPPorts = [
    80 # OnlyOffice (nginx) — Traefik -> here
    9200 # OpenCloud proxy — Traefik -> here
  ];

  # Dedicated second disk for all of OpenCloud's state (user files, spaces,
  # search index, NATS/KV, thumbnails — everything under OC_BASE_DATA_PATH),
  # kept off the OS disk. Same treatment as proxmox-vm.nix's `main` disk:
  # disko partitions, formats, and mounts it, and contributes the matching
  # `fileSystems` entry to the built system. Mounted straight onto the
  # service's stateDir rather than /mnt/… so the NixOS module's defaults
  # (user home, tmpfiles, ReadWritePaths) all line up with no extra glue.
  # `nofail` (a missing/unplugged disk shouldn't block boot) is offset by
  # `RequiresMountsFor` on opencloud.service below, so a missing mount
  # fails loud (opencloud won't start) instead of silently filling the root
  # disk with user uploads.
  #
  # In Proxmox: add this as a second disk on the same SCSI controller as
  # the OS disk (VirtIO SCSI single) so it shows up as /dev/sdb, matching
  # how the OS disk is guaranteed to land on /dev/sda.
  disko.devices.disk.data = {
    device = "/dev/sdb";
    type = "disk";
    content = {
      type = "gpt";
      partitions.data = {
        size = "100%";
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/var/lib/opencloud";
          mountOptions = [
            "noatime"
            "nofail"
          ];
        };
      };
    };
  };

  # Grow the data disk to fill its virtual disk on every boot, the same way
  # container-host.nix does for the root disk — so enlarging sdb in Proxmox
  # is all it takes to get more OpenCloud storage. Two steps, both needed:
  # `growpart-data` extends the GPT partition itself (no-op if already full
  # size), then `autoResize` adds `x-systemd.growfs` to the mount so systemd
  # grows the ext4 filesystem to match right after mounting. boot.growPartition
  # only ever handles the partition under `/`, so the first step is a copy
  # of its unit pointed at sdb1 instead.
  fileSystems."/var/lib/opencloud".autoResize = true;
  systemd.services.growpart-data = {
    wantedBy = [ "var-lib-opencloud.mount" ];
    before = [
      "var-lib-opencloud.mount"
      "shutdown.target"
    ];
    after = [ "dev-sdb.device" ];
    conflicts = [ "shutdown.target" ];
    unitConfig = {
      DefaultDependencies = false;
      # Disk unplugged/missing: skip quietly and let `nofail` on the mount
      # (and RequiresMountsFor on opencloud.service) handle it.
      ConditionPathExists = "/dev/sdb";
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutSec = "infinity";
      # growpart returns 1 if the partition is already grown
      SuccessExitStatus = "0 1";
      ExecStart = "${pkgs.cloud-utils.guest}/bin/growpart /dev/sdb 1";
    };
  };

  # ---------------------------------------------------------------------
  # OnlyOffice DocumentServer. The NixOS module brings its own nginx
  # vhost, postgres DB, and rabbitmq. WOPI is how OpenCloud talks to it
  # (OpenCloud's `collaboration` service is the WOPI host); OnlyOffice's
  # own JWT is a separate mechanism only used by the non-WOPI API, so no
  # jwtSecretFile here.
  # ---------------------------------------------------------------------
  services.onlyoffice = {
    enable = true;
    hostname = builtins.replaceStrings [ "https://" ] [ "" ] officeUrl; # nginx server_name
    wopi = true;
    # OnlyOffice refuses to fetch documents from private/loopback addresses
    # by default. The WOPI source it has to call back into is the
    # collaboration service on 127.0.0.1:9300 (COLLABORATION_WOPI_SRC
    # below), so that guard has to come off.
    allowLocalConnections = true;
    securityNonceFile = "/etc/onlyoffice/nonce.conf";
  };

  # ---------------------------------------------------------------------
  # OpenCloud, in the NixOS module's `fullstack` supervised mode (one
  # process, all microservices). The built-in IDM is excluded and every
  # user/group/auth lookup points at the remote lldap instead; the
  # `collaboration` service is added on top to drive OnlyOffice over WOPI.
  # ---------------------------------------------------------------------
  services.opencloud = {
    enable = true;
    address = "0.0.0.0"; # Traefik lives on another host
    url = cloudUrl;
    # stateDir is left at its default, /var/lib/opencloud — that's the
    # mountpoint of the data disk above.

    # OC_LDAP_BIND_PASSWORD, COLLABORATION_WOPI_SECRET, OC_ADMIN_USER_ID.
    # Anything here overrides `environment` and `settings`.
    environmentFile = "/etc/opencloud.env";

    environment = {
      # Internal service-to-service traffic uses self-signed certs; Traefik
      # terminates the real TLS in front of :9200, so the proxy itself
      # serves plain HTTP.
      OC_INSECURE = "true";
      PROXY_TLS = "false";
      OC_LOG_LEVEL = "warn";

      # Drop the built-in IDM (lldap is the directory), add the WOPI host.
      OC_EXCLUDE_RUN_SERVICES = "idm";
      OC_ADD_RUN_SERVICES = "collaboration";

      # --- LDAP: the existing lldap on 10.87.6.10 ------------------------
      # The OC_LDAP_* vars fan out to every service that touches the
      # directory (graph, users, groups, auth-basic, idp). Attribute names
      # are what lldap actually answers with: users are inetOrgPerson under
      # ou=people with uid/mail/cn/entryUUID, groups are
      # groupOfUniqueNames under ou=groups with cn/member/entryUUID.
      OC_LDAP_URI = ldapUri;
      OC_LDAP_INSECURE = "true"; # plain ldap://, no TLS to verify
      OC_LDAP_BIND_DN = ldapBindDn;
      # lldap is the source of truth; OpenCloud never creates/edits/disables
      # users itself (its admin UI user management goes read-only).
      OC_LDAP_SERVER_WRITE_ENABLED = "false";
      OC_LDAP_DISABLE_USER_MECHANISM = "none";

      OC_LDAP_USER_BASE_DN = "ou=people,${ldapBaseDn}";
      OC_LDAP_USER_SCHEMA_ID = "entryUUID";
      # To restrict login to one lldap group instead of every user, set e.g.
      OC_LDAP_USER_FILTER = "(memberOf=cn=nextcloud_users,ou=groups,${ldapBaseDn})";

      OC_LDAP_GROUP_BASE_DN = "ou=nextcloud_users,${ldapBaseDn}";
      OC_LDAP_GROUP_SCHEMA_ID = "entryUUID";

      # The built-in IdP authenticates against LDAP too; `uid` is what the
      # login form's username field is matched on.
      IDP_LDAP_LOGIN_ATTRIBUTE = "uid";
      IDP_LDAP_UUID_ATTRIBUTE_TYPE = "text";

      # --- WOPI: OnlyOffice ----------------------------------------------
      COLLABORATION_APP_NAME = "OnlyOffice";
      COLLABORATION_APP_PRODUCT = "OnlyOffice";
      COLLABORATION_APP_DESCRIPTION = "Open office documents with OnlyOffice";
      # Where the *browser* loads the editor from — OnlyOffice's WOPI
      # discovery is fetched from here too, so it has to be the public
      # (Traefik) URL, not localhost.
      COLLABORATION_APP_ADDR = officeUrl;
      COLLABORATION_APP_INSECURE = "false";
      # Where *OnlyOffice* calls back into OpenCloud to fetch/save the
      # document. Server-to-server on the same box, so loopback is fine
      # (and is why allowLocalConnections is on above); the collaboration
      # service's HTTP listener defaults to 127.0.0.1:9300.
      COLLABORATION_WOPI_SRC = "http://127.0.0.1:9300";
    };
  };

  systemd.services.opencloud = {
    # The WOPI app registration needs OnlyOffice's discovery endpoint up;
    # lldap is on another host, so the network being online is all we can
    # order against for that (and Restart=always covers it being slow).
    after = [
      "network-online.target"
      "onlyoffice-docservice.service"
    ];
    wants = [
      "network-online.target"
      "onlyoffice-docservice.service"
    ];

    # Hard-fail startup instead of silently writing to the root disk if
    # /var/lib/opencloud (the data disk, `nofail`) didn't actually mount —
    # the same failure mode attic guards against.
    unitConfig.RequiresMountsFor = [ "/var/lib/opencloud" ];
  };

  environment.systemPackages = [
    pkgs.openldap # `ldapsearch` against the remote lldap, for entryUUIDs / debugging the mapping
  ];

  system.stateVersion = "26.05";
}
