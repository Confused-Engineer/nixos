{ lib, pkgs, config, ... }:
let
  cfg = config.custom.systemd.system-api;
in {
  options.custom.systemd.system-api = {
    enable = lib.mkEnableOption "system-api HTTP service for Home Assistant";
  };

  config = lib.mkIf cfg.enable {
    # system-api listens on TCP 5002.
    networking.firewall.allowedTCPPorts = [ 5002 ];

    environment.systemPackages = [ pkgs.system-api ];

    systemd.services.systemapi = {
      enable      = true;
      description = "System API for Home Assistant";
      wantedBy    = [ "network.target" ];
      serviceConfig = {
        ExecStart  = "${pkgs.system-api}/bin/system_api";
        Restart    = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
