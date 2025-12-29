{ lib, pkgs, config, ... }:
with lib;                      
let
  # Shorter name to access final settings a 
  # user of hello.nix module HAS ACTUALLY SET.
  # cfg is a typical convention.
  cfg = config.custom.apps.lact;
in {
  # Declare what settings a user of this "hello.nix" module CAN SET.
  options.custom.apps = {
  
    lact = {
      enable = mkEnableOption "GPU Overclocking tool";
    };

  };
  # Define what other settings, services and resources should be active IF
  # a user of this "hello.nix" module ENABLED this module 
  # by setting "services.hello.enable = true;".
  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.lact ];
    systemd.services.lact = {
      description = "GPU Control Daemon";
      after = ["multi-user.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStart = "${pkgs.lact}/bin/lact daemon";
      };
      enable = true;
    };
  };
}