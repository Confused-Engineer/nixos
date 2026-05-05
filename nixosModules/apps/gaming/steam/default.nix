{ lib, pkgs, config, ... }:
let
  cfg = config.custom.apps.steam;
in {
  options.custom.apps.steam = {
    enable         = lib.mkEnableOption "Steam";
    systemd.enable = lib.mkEnableOption "auto-start Steam in the background at login";
  };

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable                            = true;
      remotePlay.openFirewall           = true;
      dedicatedServer.openFirewall      = true;
      localNetworkGameTransfers.openFirewall = true;
      extraCompatPackages               = [ pkgs.proton-ge-bin ];
    };

    systemd.user.services.steam = lib.mkIf cfg.systemd.enable {
      enable      = true;
      description = "Steam (background, silent)";
      wantedBy    = [ "graphical-session.target" ];
      after       = [ "network.target" ];
      serviceConfig = {
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 3";
        ExecStart    = "${pkgs.steam}/bin/steam -nochatui -nofriendsui -silent %U";
        Restart      = "on-failure";
        RestartSec   = "5s";
      };
    };
  };
}
