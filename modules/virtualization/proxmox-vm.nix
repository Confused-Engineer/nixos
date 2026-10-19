# Generic disko-partitioned Proxmox VM disk layout and hardware profile.
# Pulls in the disko NixOS module itself, so a host gets `disko.devices`
# (e.g. for a second data disk, see attic/opencloud) just by importing this.
{ inputs, ... }:
{
  flake.modules.nixos.proxmox-vm =
    { lib, ... }:
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
    };
}
