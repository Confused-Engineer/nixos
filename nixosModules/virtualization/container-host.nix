# Baseline for a headless, root-only, podman-container-only Proxmox VM:
# controller, server-template, music-assist, dns1, and dns2 all enable this
# instead of repeating the same ~60 lines. Per-host files keep only what's
# actually per-host: networking.hostName, this option, and containers.nix.
{
  lib,
  config,
  ...
}:
let
  cfg = config.custom.virtualization.container-host;
  keys = import ../../users/keys.nix;
in
{
  options.custom.virtualization.container-host = {
    enable = lib.mkEnableOption "baseline for a headless, root-only, podman-container-only Proxmox VM";

    autoUpgrade.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Unattended monthly rebuild+reboot via `system.autoUpgrade`. Leave
        this off for a host like `server-template` that gets shut down and
        converted to a Proxmox template right after install, rather than
        running long-term unattended.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    custom.os.boot = {
      enable = true;
      systemd = true; # UEFI + systemd-boot — give the VM an OVMF/EFI disk in Proxmox
    };

    # Keep only the current generation + 1 previous — these boxes are
    # backed up, so anything further back is "restore from backup"
    # territory anyway.
    custom.os.gc = {
      enable = true;
      generations = 2;
    };

    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [ "root" ];
      # Hardlink identical files across store paths — real disk savings on
      # a small VM disk, at the cost of a little extra CPU during GC.
      auto-optimise-store = true;
      # Belt-and-suspenders: trigger GC automatically the moment free space
      # drops below 1GB, not just on the weekly timer. Stops once 3GB is
      # free.
      min-free = 1 * 1024 * 1024 * 1024;
      max-free = 3 * 1024 * 1024 * 1024;
    };

    # oci-containers defaults to the podman backend (stateVersion >= 22.05),
    # which speaks the Docker API over its own socket rather than
    # /var/run/docker.sock. dockerSocket.enable symlinks the podman socket
    # to that path so Docker-oriented images (portainer, docker-socket-
    # proxy) keep working unmodified.
    virtualisation.podman.dockerSocket.enable = true;

    # Weekly `podman system prune`, so image/layer churn from updating
    # containers doesn't accumulate forever.
    virtualisation.podman.autoPrune.enable = true;

    # systemd-nspawn/machinectl containers — a separate subsystem from the
    # podman containers these hosts actually run; nothing here uses it.
    boot.enableContainers = false;

    # Weekly TRIM so blocks freed by nix GC / podman prune actually get
    # returned to Proxmox's (thin-provisioned) storage, not just freed
    # inside the VM's own filesystem.
    services.fstrim.enable = true;

    # Unattended VM, nobody's rotating logs by hand — bound the journal.
    # SystemMaxUse caps persistent storage, RuntimeMaxUse caps the
    # in-memory journal used whenever persistent storage isn't set up.
    services.journald.extraConfig = ''
      SystemMaxUse=200M
      RuntimeMaxUse=100M
    '';

    # cloud-init renders networkd config from Proxmox-supplied metadata per
    # clone, so networkd (not the scripted dhcpcd backend) has to own it.
    networking.useNetworkd = true;

    time.timeZone = "America/New_York";
    i18n.defaultLocale = "en_US.UTF-8";

    # Headless container host — skip building/installing man pages, the
    # NixOS manual, and option docs; nothing here ever reads them.
    documentation.enable = false;
    documentation.nixos.enable = false;
    documentation.man.enable = false;
    documentation.doc.enable = false;
    documentation.info.enable = false;

    # perl/rsync/strace ship on every NixOS system by default even though
    # nothing here uses them — switch-to-configuration-ng (Rust) doesn't
    # need perl like the old activation script did, so there's no hidden
    # dependency on it either. Explicitly documented as safe to drop for a
    # minimal host.
    environment.defaultPackages = [ ];

    # Proxmox metrics/actions (shutdown, status, IP reporting) go through
    # the guest agent; cloud-init applies the per-clone metadata Proxmox
    # injects.
    services.qemuGuest.enable = true;
    services.cloud-init = {
      enable = true;
      network.enable = true;
    };

    # Grow root to fill the disk on every boot, not just once at template
    # install time — covers a clone whose virtual disk got resized bigger
    # in Proxmox after the VM already existed. `growPartition` extends the
    # GPT partition itself (systemd service, runs unconditionally, no-op if
    # already full size); `autoResize` then grows the ext4 filesystem to
    # match via `x-systemd.growfs`. Both are needed — growing the partition
    # alone leaves the filesystem the old size.
    boot.growPartition = true;
    fileSystems."/".autoResize = true;

    # Root-only SSH: rootful podman means a container escape already lands
    # at host root, so a separate wheel/sudo user buys no real privilege
    # separation here — it only matters for a lateral pivot from another
    # account, which isn't this host's threat model.
    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.AllowUsers = [ "root" ];
      settings.PermitRootLogin = "prohibit-password";
    };
    users.users.root.openssh.authorizedKeys.keys = keys.david;

    # Monthly, unattended, restart if the new generation needs it — nobody's
    # watching a headless VM's console.
    system.autoUpgrade = lib.mkIf cfg.autoUpgrade.enable {
      enable = true;
      flake = "github:Confused-Engineer/nixos#${config.networking.hostName}";
      flags = [
        "--refresh"
        "--no-write-lock-file"
      ];
      dates = "*-*-01 04:00:00";
      operation = "boot";
      randomizedDelaySec = "5h";
      allowReboot = true;
    };
  };
}
