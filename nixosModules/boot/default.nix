{ lib, pkgs, config, ... }:
let
  cfg = config.custom.boot;
in
{
  options.custom.boot = {
    enable = lib.mkEnableOption "enable custom boot";
    fancy.enable = lib.mkEnableOption "enable fancy gui boot";
    fancy.secureBoot = lib.mkEnableOption "enable secure boot for fancy boot";
    systemd = lib.mkEnableOption "normal systemd boot";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        boot.loader.systemd-boot.enable = cfg.systemd && !cfg.fancy.enable;
      }

      # Fancy boot: limine + plymouth + kernel tweaks
      (lib.mkIf cfg.fancy.enable {
        boot = {
          loader = {
            limine.enable = true;
            limine.secureBoot.enable = cfg.fancy.secureBoot;
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
          kernelParams = [
            "quiet"
            "splash"
            "boot.shell_on_fail"
          ];

        };
      })
    ]
  );
}
