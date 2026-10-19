# KDE Plasma 6. Like every de-* aspect, keeps an `enable` option
# (default on) so specialisations can switch it off — see de-cosmic.nix.
{
  flake.modules.nixos.de-kde =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.custom.de-kde;
    in
    {
      options.custom.de-kde = {
        enable = lib.mkEnableOption "KDE Plasma 6" // {
          default = true;
        };
        strip.enable = lib.mkEnableOption "remove most default KDE apps";
      };

      config = lib.mkIf cfg.enable {
        services.xserver.enable = true;
        services.displayManager.sddm.enable = true;
        services.displayManager.sddm.wayland.enable = true;
        services.desktopManager.plasma6.enable = true;

        environment.plasma6.excludePackages = lib.mkIf cfg.strip.enable (
          with pkgs;
          [
            kdePackages.elisa
            kdePackages.kdepim-runtime
            kdePackages.kmahjongg
            kdePackages.kmines
            kdePackages.konversation
            kdePackages.kpat
            kdePackages.ksudoku
            kdePackages.ktorrent
            mpv
          ]
        );
      };
    };
}
