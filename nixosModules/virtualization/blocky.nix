# ghcr.io/0xerr0r/blocky — ad-blocking DNS resolver / conditional forwarder.
# dns1 and dns2 both enable this to run an identical, redundant pair, so the
# config lives here once instead of being duplicated across two
# machines/<host>/containers.nix files.
{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.custom.virtualization.blocky;

  configFile = pkgs.writeText "blocky-config.yml" ''
    upstreams:
      groups:
        default:
          - 8.8.8.8

    customDNS:
      customTTL: 1h
      filterUnmappedTypes: true
      mapping:
        a5f.org: 10.87.6.10
        lancache.steamcontent.com: 10.87.10.22

    conditional:
      fallbackUpstream: false
      mapping:
        internal: 10.87.10.1
        .: 10.87.10.1
        87.10.in-addr.arpa: 10.87.10.1

    blocking:
      denylists:
        ads:
          - https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
      clientGroupsBlock:
        default: [ads, malware]
  '';
in
{
  options.custom.virtualization.blocky = {
    enable = lib.mkEnableOption "blocky DNS resolver container";
  };

  config = lib.mkIf cfg.enable {
    # networking.useNetworkd (set by custom.virtualization.container-host)
    # defaults services.resolved.enable to true, whose stub listener sits on
    # 127.0.0.53/127.0.0.54:53 — a specific-address bind that collides with
    # Blocky's wildcard `:53` bind at the kernel level ("address already in
    # use"), even though the addresses don't literally match. Keep resolved
    # itself on (DHCP-learned upstream servers still flow through it), just
    # turn off its stub listener, and repoint /etc/resolv.conf at resolved's
    # non-stub file so this host's own outbound DNS (image pulls, flake
    # fetches) keeps working without going through the now-disabled stub.
    services.resolved.settings.Resolve.DNSStubListener = "no";
    environment.etc."resolv.conf".source = lib.mkForce "/run/systemd/resolve/resolv.conf";

    # NixOS's firewall defaults to dropping anything not explicitly
    # allowed — publishing the container port doesn't open a hole in it on
    # its own. Without this, Blocky only answers queries from localhost.
    networking.firewall.allowedTCPPorts = [ 53 ];
    networking.firewall.allowedUDPPorts = [ 53 ];

    virtualisation.oci-containers.containers.blocky = {
      autoStart = true;
      image = "ghcr.io/0xerr0r/blocky:latest";
      volumes = [
        "${configFile}:/app/config.yml:ro"
      ];
      ports = [
        "53:53/tcp"
        "53:53/udp"
      ];
    };
  };
}
