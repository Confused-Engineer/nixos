# Proxmox VM clone of server-template, running as a container host.
# The proxmox-vm and container-host aspects carry all the shared disk/OS
# boilerplate (modules/virtualization/). This host adds only its
# containers (containers.nix, which also contributes to this host module).
{ inputs, self, ... }:
{
  flake.nixosConfigurations.terraria = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ self.modules.nixos.terraria ];
  };

  flake.modules.nixos.terraria = {
    imports = with self.modules.nixos; [
      nixpkgs
      binary-cache

      proxmox-vm
      container-host
    ];

    networking.hostName = "terraria";

    system.stateVersion = "26.05";
  };
}
