{ lib, pkgs, config, ... }:
let
  cfg     = config.custom.os.ui.cosmic;
  helpers = import ./../../../../lib { inherit lib pkgs; };
in {
  options.custom.os.ui.cosmic = {
    enable             = lib.mkEnableOption "COSMIC desktop";
    strip.enable       = lib.mkEnableOption "remove the cosmic-store and other defaults";
    nvidiaFix.hibernate = lib.mkEnableOption "STOP/CONT cosmic-osd around suspend (NVIDIA hibernate fix)";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      services.displayManager.cosmic-greeter.enable = true;
      services.desktopManager.cosmic.enable         = true;

      environment.cosmic.excludePackages = lib.mkIf cfg.strip.enable [
        pkgs.cosmic-store
      ];
    }

    (lib.mkIf cfg.nvidiaFix.hibernate {
      systemd = helpers.mkNvidiaSuspendFix {
        name   = "cosmic";
        binary = "${pkgs.cosmic-osd}/bin/cosmic-osd";
      };
    })
  ]);
}
