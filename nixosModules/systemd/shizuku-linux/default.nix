{ lib, pkgs, config, ... }:
let
  cfg = config.custom.systemd.shizuku-linux;
in {
  options.custom.systemd.shizuku-linux = {
    enable = lib.mkEnableOption "shizuku-linux helper that starts Shizuku on Android device plug-in";
  };

  config = lib.mkIf cfg.enable {
    # Shizuku speaks to the device over ADB; no inbound network is required.
    environment.systemPackages = [ pkgs.shizuku-linux ];
    programs.adb.enable        = true;

    systemd.services.shizuku-linux = {
      enable      = true;
      description = "Start Shizuku on device plug-in";
      wantedBy    = [ "network.target" ];
      serviceConfig = {
        ExecStart  = "${pkgs.shizuku-linux}/bin/shizuku_linux";
        Restart    = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
