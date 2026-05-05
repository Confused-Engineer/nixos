{ lib, pkgs, config, ... }:
let
  cfg = config.custom.hardware.gpu.lact;
in {
  options.custom.hardware.gpu.lact = {
    enable = lib.mkEnableOption "LACT GPU control daemon";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.lact ];

    systemd.services.lact = {
      enable      = true;
      description = "LACT GPU control daemon";
      after       = [ "multi-user.target" ];
      wantedBy    = [ "multi-user.target" ];
      serviceConfig.ExecStart = "${pkgs.lact}/bin/lact daemon";
    };
  };
}
