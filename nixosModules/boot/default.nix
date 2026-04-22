{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.custom.boot;
in {
  options.custom.boot = {
    enable  = mkEnableOption "enable custom boot";
    fancy   = mkEnableOption "nitch";
    systemd = mkEnableOption "Nixos-Rebuild alias's";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      boot.loader.systemd-boot.enable = cfg.systemd && !cfg.fancy;
    }

    # Fancy boot: limine + plymouth + kernel tweaks
    (mkIf cfg.fancy {
      boot = {
        loader = {
          limine.enable = true;
          limine.secureBoot.enable = true;
          efi.canTouchEfiVariables = true;
        };

        plymouth = {
          enable = true;
          theme = "circle";
          themePackages = with pkgs; [
            (adi1090x-plymouth-themes.override {
              selected_themes = [ "circle" ];
            })
          ];
        };

        initrd.systemd.enable = true;
        consoleLogLevel = 0;
        kernelPackages = pkgs.linuxPackages_latest;
        kernelParams = [ "quiet" "splash" "boot.shell_on_fail" ];
        kernelModules = [ "ntsync" ];
      };
    })
  ]);
}