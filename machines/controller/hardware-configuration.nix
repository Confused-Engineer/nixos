# Hand-written for a Proxmox VM (no real hardware to detect). Covers the
# virtio devices Proxmox exposes; fileSystems come from disko.nix instead
# of a `nixos-generate-config` scan, since disko owns the partition table.
{ lib, ... }:
{
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
}
