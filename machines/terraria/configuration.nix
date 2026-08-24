# Proxmox VM clone of server-template, running as a container host.
# custom.virtualization.proxmox-vm and custom.virtualization.container-host
# carry all the shared disk/OS boilerplate — see
# nixosModules/virtualization/proxmox-vm.nix and
# nixosModules/virtualization/container-host.nix. This file only has what's
# actually specific to this host.
{ ... }:
{
  imports = [
    ./containers.nix
    ./../../nixosModules
    ./../../nixosModules/virtualization/proxmox-vm.nix
  ];

  custom.virtualization.proxmox-vm.enable = true;
  custom.virtualization.container-host.enable = true;

  networking.hostName = "terraria";

  system.stateVersion = "26.05";
}
