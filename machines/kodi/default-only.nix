{ config, pkgs, ... }:
{
  config = lib.mkIf (config.specialisation != {}) {

    custom = {

      os = {
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