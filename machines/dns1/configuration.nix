# Proxmox VM clone of server-template, running as a Blocky DNS resolver.
# custom.virtualization.proxmox-vm and custom.virtualization.container-host
# carry the shared disk/OS boilerplate (nixosModules/virtualization/
# proxmox-vm.nix, nixosModules/virtualization/container-host.nix);
# custom.virtualization.blocky carries the DNS container itself
# (nixosModules/virtualization/blocky.nix). dns1 and dns2 run the identical
# config as a redundant pair.
{ ... }:
{
  imports = [
    ./../../nixosModules
    ./../../nixosModules/virtualization/proxmox-vm.nix
  ];

  custom.virtualization.proxmox-vm.enable = true;
  custom.virtualization.container-host.enable = true;
  custom.virtualization.blocky.enable = true;

  networking.hostName = "dns1";

  system.stateVersion = "26.05";
}
