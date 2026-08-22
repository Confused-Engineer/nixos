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
