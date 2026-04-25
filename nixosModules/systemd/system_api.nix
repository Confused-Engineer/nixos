{ lib, pkgs, config, ... }:                  
let
  # Shorter name to access final settings a 
  # user of hello.nix module HAS ACTUALLY SET.
  # cfg is a typical convention.
  cfg = config.custom.systemd.system_api;
in {
  # Declare what settings a user of this "hello.nix" module CAN SET.
  options.custom.systemd = {
  
    system_api = {
      enable = lib.mkEnableOption "Setup System API";
    };


  };
  # Define what other settings, services and resources should be active IF
  # a user of this "hello.nix" module ENABLED this module 
  # by setting "services.hello.enable = true;".
  config = lib.mkIf cfg.enable {

    networking.firewall.allowedTCPPorts = [ 5002 ]; # Allow TCP port 80

    environment.systemPackages = with pkgs; [
      system_api
    ];


    systemd.services.systemapi = {
      enable = true;
      description = "A System API for Home Assistant";
      wantedBy = [ "network.target" ];
    # after = [ "network.target" ];
      serviceConfig = {
      # ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
        ExecStart = "${pkgs.system_api}/bin/system_api";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}