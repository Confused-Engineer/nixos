# COSMIC desktop.
#
# Desktop sessions are the one kind of aspect that keeps an `enable`
# option (default on when imported): a specialisation inherits everything
# its parent imports, so `custom.de-cosmic.enable = lib.mkForce false;`
# is how e.g. the steamos specialisation swaps the session out.
{ self, ... }:
{
  flake.modules.nixos.de-cosmic =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.custom.de-cosmic;
    in
    {
      options.custom.de-cosmic = {
        enable = lib.mkEnableOption "COSMIC desktop" // {
          default = true;
        };
        strip.enable = lib.mkEnableOption "remove the cosmic-store and other defaults";
        nvidiaFix.hibernate = lib.mkEnableOption "STOP/CONT cosmic-osd around suspend (NVIDIA hibernate fix)";
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          {
            services.displayManager.cosmic-greeter.enable = true;
            services.desktopManager.cosmic.enable = true;

            environment.cosmic.excludePackages = lib.mkIf cfg.strip.enable [
              pkgs.cosmic-store
            ];
          }

          (lib.mkIf cfg.nvidiaFix.hibernate {
            systemd = self.lib.mkNvidiaSuspendFix pkgs {
              name = "cosmic";
              binary = "${pkgs.cosmic-osd}/bin/cosmic-osd";
            };
          })
        ]
      );
    };
}
