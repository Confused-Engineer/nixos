# Boot loader: set exactly one of `fancy.enable` (limine + plymouth) or
# `systemd` (plain systemd-boot).
{
  flake.modules.nixos.boot =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.custom.boot;
    in
    {
      options.custom.boot = {
        # Pick exactly one of these two. The previous version silently
        # disabled systemd-boot whenever fancy was on, which made the
        # `systemd` option essentially dead code. Now they're explicit
        # alternatives and asserting both is a hard error.
        fancy = {
          enable = lib.mkEnableOption "limine + plymouth pretty boot";
          secureBoot = lib.mkEnableOption "secure boot for fancy boot";
        };

        systemd = lib.mkEnableOption "plain systemd-boot loader";
      };

      config = lib.mkMerge [
        {
          assertions = [
            {
              assertion = !(cfg.fancy.enable && cfg.systemd);
              message = "custom.boot: pick either fancy.enable or systemd, not both.";
            }
          ];

          # EFI variables are needed regardless of which loader is in use.
          boot.loader.efi.canTouchEfiVariables = true;
        }

        # Plain systemd-boot.
        (lib.mkIf cfg.systemd {
          boot.loader.systemd-boot.enable = true;
        })

        # Fancy: limine + plymouth + kernel-quiet tweaks.
        (lib.mkIf cfg.fancy.enable {
          boot = {
            loader.limine = {
              enable = true;
              secureBoot.enable = cfg.fancy.secureBoot;
            };

            plymouth = {
              enable = true;
              theme = "circle";
              themePackages = [
                (pkgs.adi1090x-plymouth-themes.override {
                  selected_themes = [ "circle" ];
                })
              ];
            };

            initrd.systemd.enable = true;
            consoleLogLevel = 0;
            kernelParams = [
              "quiet"
              "splash"
              "boot.shell_on_fail"
            ];
          };
        })
      ];
    };
}
