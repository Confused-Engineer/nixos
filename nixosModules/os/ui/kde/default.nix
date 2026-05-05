{ lib, pkgs, config, ... }:
let
  cfg = config.custom.os.ui.kde;
in {
  options.custom.os.ui.kde = {
    enable       = lib.mkEnableOption "KDE Plasma 6";
    strip.enable = lib.mkEnableOption "remove most default KDE apps";
  };

  config = lib.mkIf cfg.enable {
    services.xserver.enable                  = true;
    services.displayManager.sddm.enable      = true;
    services.displayManager.sddm.wayland.enable = true;
    services.desktopManager.plasma6.enable   = true;

    environment.plasma6.excludePackages = lib.mkIf cfg.strip.enable (with pkgs; [
      kdePackages.elisa
      kdePackages.kdepim-runtime
      kdePackages.kmahjongg
      kdePackages.kmines
      kdePackages.konversation
      kdePackages.kpat
      kdePackages.ksudoku
      kdePackages.ktorrent
      mpv
    ]);
  };
}
