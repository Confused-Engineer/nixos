{ config, lib, pkgs, ... }:
{
  config = lib.mkIf (config.specialisation != {}) {

    custom.os.ui.kodi.enable = true;

  };
}