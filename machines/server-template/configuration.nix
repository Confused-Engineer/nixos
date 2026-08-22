# Proxmox VM template — stable NixOS, disko-partitioned, no home-manager.
# custom.hardware.proxmox-vm and custom.os.container-host carry all the
# shared disk/OS boilerplate — see nixosModules/hardware/proxmox-vm.nix and
# nixosModules/os/container-host.nix. This file only has what's actually
# specific to this host.
#
# autoUpgrade stays off: this box gets shut down and converted to a Proxmox
# template right after install, not run long-term unattended. Clones keep
# this config until given Proxmox cloud-init metadata or rebuilt onto their
# own flake host entry (see README.md for the install procedure).
{ ... }:
{
  imports = [
    ./containers.nix
    ./../../nixosModules
    ./../../nixosModules/hardware/proxmox-vm.nix
  ];

  custom.hardware.proxmox-vm.enable = true;
  custom.os.container-host = {
    enable = true;
    autoUpgrade.enable = false;
  };

  networking.hostName = "server-template";

  system.stateVersion = "26.05";
}
