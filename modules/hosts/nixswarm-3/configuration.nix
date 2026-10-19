# Proxmox VM clone of server-template, running as a Docker Swarm node —
# replaces the Ubuntu Swarm-1/2/3 VMs. The proxmox-vm and container-host
# aspects carry the shared disk/OS boilerplate; the swarm-node aspect
# carries Docker, the /mnt/configs NFS share, and the keepalived VIP
# (modules/virtualization/swarm-node.nix). nixswarm-1/2/3 differ only in
# hostname and VIP priority.
{ inputs, self, ... }:
{
  flake.nixosConfigurations.nixswarm-3 = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ self.modules.nixos.nixswarm-3 ];
  };

  flake.modules.nixos.nixswarm-3 = {
    imports = with self.modules.nixos; [
      nixpkgs
      binary-cache

      proxmox-vm
      container-host
      swarm-node
    ];

    custom.swarm-node.vip.priority = 50; # 1 = 150 (primary), 2 = 100, 3 = 50

    networking.hostName = "nixswarm-3";

    system.stateVersion = "26.05";
  };
}
