# Proxmox VM clone of server-template, running as a Docker Swarm node —
# replaces the Ubuntu Swarm-1/2/3 VMs. custom.virtualization.proxmox-vm and
# custom.virtualization.container-host carry the shared disk/OS boilerplate;
# custom.virtualization.swarm-node carries Docker, the /mnt/configs NFS
# share, and the keepalived VIP (nixosModules/virtualization/swarm-node.nix).
# nixswarm-1/2/3 differ only in hostname and VIP priority.
{ ... }:
{
  imports = [
    ./../../nixosModules
    ./../../nixosModules/virtualization/proxmox-vm.nix
  ];

  custom.virtualization.proxmox-vm.enable = true;
  custom.virtualization.container-host.enable = true;
  custom.virtualization.swarm-node = {
    enable = true;
    vip.priority = 150; # 1 = 150 (primary), 2 = 100, 3 = 50
  };

  networking.hostName = "nixswarm-1";

  system.stateVersion = "26.05";
}
