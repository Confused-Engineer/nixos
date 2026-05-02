{ lib, pkgs, config, ... }:
let
  cfg = config.custom.apps.steam;
in
{
  options.custom.apps = {
    steam = {
      enable = lib.mkEnableOption "Install Steam";
    };
    steam.systemd = {
      enable = lib.mkEnableOption "AutoStart Steam";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
      localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
      # gamescopeSession.enable = true; # Enable a minimal desktop environment
      # package = pkgs.steam.override {
      #   extraLibraries = pkgs: [ pkgs.libxcb ];
      #   extraPkgs =
      #     pkgs: with pkgs; [
      #       libxcb
      #       libXcursor
      #       libXi
      #       libXinerama
      #       libXScrnSaver
      #       libpng
      #       libpulseaudio
      #       libvorbis
      #       stdenv.cc.cc.lib
      #       libkrb5
      #       keyutils
      #       gamemode
      #     ];
      # };
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };

    environment.systemPackages = lib.mkIf cfg.systemd.enable [ pkgs.coreutils ];

    systemd.user.services.steam = lib.mkIf cfg.systemd.enable {
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
