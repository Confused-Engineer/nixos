# Docker Swarm node: nixswarm-1/2/3 all enable this, replacing the Ubuntu
# Swarm-1/2/3 VMs. Three things on top of container-host:
#   - the real Docker daemon instead of podman (Swarm is Docker-only)
#   - the shared NFS config share from swarm-nfs, mounted on every node so a
#     service can land on any of them and find its bind mounts
#   - keepalived holding a floating VIP, so clients and Traefik point at one
#     address that survives a node going down. Per-host files only pick
#     `vip.priority`: highest live node holds it, and it moves back to the
#     highest one once that returns (VRRP preemption).
#
# Joining the swarm itself is imperative and one-off — NixOS only gets the
# daemon and ports ready. On nixswarm-1: `docker swarm init
# --advertise-addr <its IP>`, then `docker swarm join-token manager` and run
# the printed join command on nixswarm-2 and -3 (three managers keeps Raft
# quorum with one node down).
{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.custom.virtualization.swarm-node;
in
{
  options.custom.virtualization.swarm-node = {
    enable = lib.mkEnableOption "Docker Swarm node with shared NFS storage and a keepalived VIP";

    vip = {
      address = lib.mkOption {
        type = lib.types.str;
        default = "10.87.6.30/24";
        description = "Floating IP (with prefix) shared by the swarm nodes.";
      };

      priority = lib.mkOption {
        type = lib.types.ints.between 1 254;
        description = "VRRP priority; the highest live node holds the VIP.";
      };

      interface = lib.mkOption {
        type = lib.types.str;
        # What the NIC comes up as on the existing server-template clones.
        # Check with `ip -br link` if a clone differs.
        default = "eth0";
        description = "Interface VRRP runs on and the VIP gets added to.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    custom.virtualization.container-host.engine = "docker";

    # Swarm control plane + overlay networking between nodes:
    # 2377 cluster management, 7946 node gossip, 4789 VXLAN data plane.
    # Published service ports don't need opening here — Docker's ingress
    # routing mesh DNATs them in its own iptables chains ahead of nixos-fw.
    networking.firewall = {
      allowedTCPPorts = [
        2377
        7946
      ];
      allowedUDPPorts = [
        7946
        4789
      ];
    };

    # Same options as the old nodes' fstab line. `hard` so a swarm-nfs blip
    # stalls I/O and resumes rather than handing containers EIO mid-write.
    # nofail keeps an NFS outage from dropping boot into emergency mode;
    # docker waits on the mount below instead.
    fileSystems."/mnt/configs" = {
      device = "10.87.6.20:/mnt/configs";
      fsType = "nfs";
      options = [
        "rw"
        "nconnect=16"
        "tcp"
        "hard"
        "intr"
        "timeo=600"
        "retrans=2"
        "rsize=524288"
        "wsize=524288"
        "nofail"
      ];
    };

    # Don't let Docker start tasks against an empty local /mnt/configs if
    # the share isn't mounted — they'd write their config onto this VM's
    # root disk and come up looking freshly installed.
    systemd.services.docker.unitConfig.RequiresMountsFor = [ "/mnt/configs" ];

    services.keepalived = {
      enable = true;
      openFirewall = true; # VRRP (IP proto 112) between the nodes

      # Give up the VIP if this node's Docker daemon dies, so traffic
      # doesn't land on a box that can't serve the routing mesh.
      # is-active needs no privileges; the module doesn't create its default
      # `keepalived_script` user, so run as nobody.
      vrrpScripts.docker = {
        script = "${pkgs.systemd}/bin/systemctl is-active --quiet docker.service";
        interval = 2;
        fall = 2;
        rise = 2;
        user = "nobody";
        group = "nogroup";
      };

      vrrpInstances.swarm = {
        interface = cfg.vip.interface;
        # Everyone starts BACKUP and priority decides; preemption hands the
        # VIP back to the highest-priority node once it's healthy again.
        state = "BACKUP";
        # Must be unique among VRRP groups on this VLAN.
        virtualRouterId = 30;
        priority = cfg.vip.priority;
        virtualIps = [ { addr = cfg.vip.address; } ];
        trackScripts = [ "docker" ];
      };
    };
  };
}
