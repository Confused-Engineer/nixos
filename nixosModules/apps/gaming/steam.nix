{ lib, pkgs, config, ... }:
                     
let
  # Shorter name to access final settings a 
  # user of hello.nix module HAS ACTUALLY SET.
  # cfg is a typical convention.
  cfg = config.custom.apps.steam;
in {
  # Declare what settings a user of this "hello.nix" module CAN SET.
  options.custom.apps = {
  
    steam = {
      enable = mkEnableOption "Install Steam";
    };

    steam.systemd = {
      enable = mkEnableOption "AutoStart Steam";
    };


  };
  # Define what other settings, services and resources should be active IF
  # a user of this "hello.nix" module ENABLED this module 
  # by setting "services.hello.enable = true;".
  config = mkIf cfg.enable {

    programs.steam = {
        enable = true;
        remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
        dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
        localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
        # gamescopeSession.enable = true; # Enable a minimal desktop environment 
        # gamescopeSession.enable = true;
        package = pkgs.steam.override {
          extraLibraries = pkgs: [ pkgs.libxcb ];
          extraPkgs =
            pkgs: with pkgs; [
              libxcb
              libXcursor
              libXi
              libXinerama
              libXScrnSaver
              libpng
              libpulseaudio
              libvorbis
              stdenv.cc.cc.lib
              libkrb5
              keyutils
              gamemode
            ];
        };
        extraCompatPackages = [ pkgs.proton-ge-bin ];
    };


    environment.systemPackages = mkIf (cfg.systemd.enable == true ) [ pkgs.coreutils ];
    
    systemd.user.services.steam = mkIf (cfg.systemd.enable == true ) {
        enable = true;
        description = "Open Steam in the background at boot";
        wantedBy = [ "graphical-session.target" ];
        after = [ "network.target" ];
        serviceConfig = {
            ExecStartPre = "${pkgs.coreutils}/bin/sleep 3";
            ExecStart = "${pkgs.steam}/bin/steam -nochatui -nofriendsui -silent %U";
            Restart = "on-failure";
            RestartSec = "5s";
        };
    };
  };
}