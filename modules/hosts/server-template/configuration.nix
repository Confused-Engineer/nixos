# Proxmox VM template — stable NixOS, disko-partitioned, no home-manager.
# The proxmox-vm and container-host aspects carry all the shared disk/OS
# boilerplate (modules/virtualization/). This host adds only its
# containers (containers.nix).
#
# autoUpgrade stays off: this box gets shut down and converted to a Proxmox
# template right after install, not run long-term unattended. Clones keep
# this config until given Proxmox cloud-init metadata or rebuilt onto their
# own flake host entry (see README.md for the install procedure).
{ inputs, self, ... }:
{
  flake.nixosConfigurations.server-template = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ self.modules.nixos.server-template ];
  };

  flake.modules.nixos.server-template = {
    imports = with self.modules.nixos; [
      nixpkgs
      binary-cache

      proxmox-vm
      container-host
    ];

    custom.container-host.autoUpgrade.enable = false;

    networking.hostName = "server-template";

    system.stateVersion = "26.05";
  };
}
