# Proxmox VM, cloned from server-template, running atticd — this repo's own
# binary cache. custom.virtualization.proxmox-vm and
# custom.virtualization.container-host carry the shared disk/OS boilerplate
# (nixosModules/virtualization/proxmox-vm.nix,
# nixosModules/virtualization/container-host.nix) the same way controller and
# dns1 use them, even though this host runs no podman containers — the
# baseline (root-only SSH, disko root disk, auto-upgrade, growPartition,
# journald limits, etc.) still applies. This file only has what's actually
# specific to this host: the second data disk and atticd itself.
#
# TLS termination and the public https://attic.a5f.org hostname are handled
# by Traefik outside this repo — this host only ever speaks plain HTTP on
# :8080 on the LAN.
{ config, pkgs, ... }:
{
  imports = [
    ./../../nixosModules
    ./../../nixosModules/virtualization/proxmox-vm.nix
  ];

  custom.virtualization.proxmox-vm.enable = true;
  custom.virtualization.container-host.enable = true;

  networking.hostName = "attic";
  networking.firewall.allowedTCPPorts = [ 8080 ];

  # Dedicated second disk for atticd's NAR/chunk store, kept off the OS
  # disk. Same treatment as proxmox-vm.nix's `main` disk: disko partitions,
  # formats, and mounts it, and contributes the matching `fileSystems`
  # entry to the built system — no hand-copied UUID to go stale like the
  # old host on this machine had. `nofail` (a missing/unplugged disk
  # shouldn't block boot) is offset by `RequiresMountsFor` on atticd below,
  # so a missing mount fails loud (atticd won't start) instead of silently
  # falling through to the root disk.
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
          mountpoint = "/mnt/attic";
          mountOptions = [
            "noatime"
            "nofail"
          ];
        };
      };
    };
  };

  services.atticd = {
    enable = true;

    environmentFile = "/etc/atticd.env";

    settings = {
      listen = "[::]:8080";
      database.url = "postgresql:///atticd?host=/run/postgresql";

      jwt = { };

      # Store NARs/chunks on the dedicated ext4 disk mounted at /mnt/attic
      # (see the disko.devices.disk.data block above). Postgres metadata
      # stays on the root disk.
      storage = {
        type = "local";
        path = "/mnt/attic";
      };

      # Data chunking
      #
      # Warning: If you change any of the values here, it will be
      # difficult to reuse existing chunks for newly-uploaded NARs
      # since the cutpoints will be different. As a result, the
      # deduplication ratio will suffer for a while after the change.
      chunking = {
        # The minimum NAR size to trigger chunking. Must stay non-zero —
        # at 0, atticd stores each NAR as one monolithic object with no
        # dedup, so a large upload becomes one long-running request instead
        # of many small chunked ones.
        nar-size-threshold = 64 * 1024; # 64 KiB

        min-size = 16 * 1024; # 16 KiB
        avg-size = 64 * 1024; # 64 KiB
        max-size = 256 * 1024; # 256 KiB
      };

      # zstd level 8 is well past the point of diminishing returns for NARs
      # and costs real CPU on a 1-vCPU guest, holding each upload connection
      # open longer. 3 compresses nix store paths nearly as well, much faster.
      compression = {
        type = "zstd";
        level = 3;
      };

      # GC sweeps unreferenced chunks. Per-cache retention is set with
      # `attic cache configure <name> --retention-period <duration>`;
      # this is just the global default for caches that don't override.
      garbage-collection = {
        interval = "12 hours";
        default-retention-period = "2 weeks";
      };
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "atticd" ];
    ensureUsers = [
      {
        name = "atticd";
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.services.atticd = {
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];

    # Hard-fail startup instead of silently writing to the root disk if
    # /mnt/attic (data-mounts.nix, `nofail`) didn't actually mount — a
    # config the old host on this machine got bitten by: a wrong disk UUID
    # lets `nofail` boot clean while atticd quietly starts writing NARs
    # into the root filesystem, corrupting large uploads once it filled up.
    # This makes that failure loud (atticd won't start) instead of silent.
    unitConfig.RequiresMountsFor = [ "/mnt/attic" ];

    # atticd runs under a systemd DynamicUser, so /mnt/attic (owned by root
    # from the mount) isn't writable by it out of the box. The `+` prefix
    # runs this as root outside the sandbox before the daemon starts; the
    # transient `atticd` user resolves via nss-systemd, so `install` can hand
    # the storage directory to it. Idempotent — re-applied on every start.
    serviceConfig.ExecStartPre = [
      "+${pkgs.coreutils}/bin/install -d -o atticd -g atticd -m 0750 /mnt/attic"
    ];
  };

  environment.systemPackages = [
    pkgs.attic-client # `attic` CLI for managing the local server
  ];

  system.stateVersion = "26.05";
}
