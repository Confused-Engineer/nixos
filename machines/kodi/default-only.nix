{ config, pkgs, lib, ... }:
{
  config = lib.mkIf (config.specialisation != {}) {

    custom = {

      os = {
        autoClean.enable = true; # Clean System images greater than 7 days old
        autoUpgrade.enable = true;
        ui.kodi.enable = true;
      };    
    };

    services.xserver.desktopManager.kodi.package = (pkgs.kodi.withPackages (kodiPkgs: with kodiPkgs; [
      jellyfin
      inputstream-adaptive
      pvr-iptvsimple
    ]));
  };
}