{ lib, pkgs, config, ... }:
with lib;                      
let
  # Shorter name to access final settings a 
  # user of hello.nix module HAS ACTUALLY SET.
  # cfg is a typical convention.
  cfg = config.services.custom.steam.systemd;
in {
  # Declare what settings a user of this "hello.nix" module CAN SET.
  options.services.custom = {
  
    steam.systemd = {
      enable = mkEnableOption "AutoStart Steam";
    };


  };
  # Define what other settings, services and resources should be active IF
  # a user of this "hello.nix" module ENABLED this module 
  # by setting "services.hello.enable = true;".
  config = mkIf cfg.enable {

    environment.systemPackages = with pkgs; [ coreutils ];
    
    systemd.user.services.steam = {
        enable = true;
        description = "Open Steam in the background at boot";
        wantedBy = [ "graphical-session.target" ];
        after = [ "network.target" ];
        serviceConfig = {
            ExecStartPre = "${pkgs.coreutils}/bin/sleep 1";
            ExecStart = "${pkgs.steam}/bin/steam -nochatui -nofriendsui -silent %U";
            Restart = "on-failure";
            RestartSec = "5s";
        };
    };
  };
}