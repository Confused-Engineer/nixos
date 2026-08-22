# Proxmox VM clone of server-template, running as a container host.
# custom.hardware.proxmox-vm and custom.os.container-host carry all the
# shared disk/OS boilerplate — see nixosModules/hardware/proxmox-vm.nix and
# nixosModules/os/container-host.nix. This file only has what's actually
# specific to this host.
{ ... }:
{
  imports = [
    ./containers.nix
    ./../../nixosModules
    ./../../nixosModules/hardware/proxmox-vm.nix
  ];

  custom.hardware.proxmox-vm.enable = true;
  custom.os.container-host.enable = true;

  networking.hostName = "music-assist";

  system.stateVersion = "26.05";
}
