# Generic disko-partitioned Proxmox VM disk layout and hardware profile.
# Pulls in the disko NixOS module itself, so a host gets `disko.devices`
# (e.g. for a second data disk, see attic/opencloud) just by importing this.
{ inputs, ... }:
{
  flake.modules.nixos.proxmox-vm =
    { config, lib, ... }:
    {
      imports = [ inputs.disko.nixosModules.disko ];

      # Declarative partition table for the Proxmox VM disk. Consumed both by
      # `disko` at install time (partitions + formats + mounts /dev/sda) and
      # by the built system (contributes the matching `fileSystems.*`
      # entries), so there is no hand-written fstab to keep in sync.
      disko.devices.disk.main = {
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };

      # Hand-written for a Proxmox VM (no real hardware to detect). Covers the
      # virtio devices Proxmox exposes; fileSystems come from disko above
      # instead of a `nixos-generate-config` scan.
      boot.initrd.availableKernelModules = [
        "ahci"
        "xhci_pci"
        "virtio_pci"
        "virtio_scsi"
        "sd_mod"
        "sr_mod"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ ];
      boot.extraModulePackages = [ ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

      # ---------------------------------------------------------------------
      # Gentle, reliable self-updates. These VMs are small and run real
      # services, so an unattended `nixos-upgrade` (or any local build) should
      # take longer rather than starve the services or run out of memory and
      # fail. Most of an upgrade comes from attic / cache.nixos.org anyway;
      # this matters for the few things that have to build locally.
      # mkDefault throughout, so one host can loosen it if it ever needs to.
      # ---------------------------------------------------------------------
      nix.settings = {
        # One derivation at a time, one core each: at most a single compiler
        # in memory, and the other vCPUs stay free for the services.
        max-jobs = lib.mkDefault 1;
        cores = lib.mkDefault 1;
        # If a cache is unreachable or misses a path, build it locally instead
        # of failing the whole upgrade.
        fallback = lib.mkDefault true;
        # Ride out a flaky network instead of failing a download.
        connect-timeout = lib.mkDefault 15;
        download-attempts = lib.mkDefault 10;
      };

      # Builds run at the lowest priority. `batch` (not `idle`) so a busy VM
      # still gives them CPU time and the upgrade finishes; I/O stays
      # best-effort at the lowest priority for the same reason.
      nix.daemonCPUSchedPolicy = lib.mkDefault "batch";
      nix.daemonIOSchedClass = lib.mkDefault "best-effort";
      nix.daemonIOSchedPriority = lib.mkDefault 7;

      # The disko layout has no swap partition. Compressed RAM swap gives a
      # memory spike from evaluation or a build somewhere to go besides the
      # OOM killer. It costs nothing until it is used.
      zramSwap = {
        enable = lib.mkDefault true;
        memoryPercent = lib.mkDefault 50;
      };

      # A failed upgrade (network blip, cache down, OOM) retries instead of
      # waiting for the next scheduled run, which is a month away on the
      # container hosts. Three attempts, 15 minutes apart. `persistent` (on by
      # default) already catches up on a run missed while the VM was off.
      systemd.services.nixos-upgrade = lib.mkIf config.system.autoUpgrade.enable {
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = "15min";
        };
        unitConfig = {
          StartLimitIntervalSec = "2h";
          StartLimitBurst = 3;
        };
      };
    };
}
