# Proxmox VM clone of server-template, running as a Blocky DNS resolver.
# The proxmox-vm and container-host aspects carry the shared disk/OS
# boilerplate; the blocky aspect carries the DNS container itself
# (modules/virtualization/blocky.nix). dns1 and dns2 run the identical
# config as a redundant pair.
{ inputs, self, ... }:
{
  flake.nixosConfigurations.dns1 = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ self.modules.nixos.dns1 ];
  };

  flake.modules.nixos.dns1 = {
    imports = with self.modules.nixos; [
      nixpkgs
      binary-cache

      proxmox-vm
      container-host
      blocky
    ];

    networking.hostName = "dns1";

    system.stateVersion = "26.05";
  };
}
