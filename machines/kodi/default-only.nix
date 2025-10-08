{ config, pkgs, lib, ... }:
{
  config = lib.mkIf (config.specialisation != {}) {

      custom = {
        apps = {
          browsers.firefox = {
            enable = true;
            privacy = "strict";
            homepage = "https://hp.a5f.org/";
          };
        };

        os = {
          autoClean.enable = true; # Clean System images greater than 7 days old
          autoUpgrade.enable = true;

          ui = {
            gnome = {
              enable = true; # Use gnome
              strip.enable = true;
              extensions.enable = true;
              disable.hibernate = false;
            };
          };
        };    
      };

      environment.systemPackages = with pkgs; [
      #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      #  wget
        vscode
        git
      ];
  };
}