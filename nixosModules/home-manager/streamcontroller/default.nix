# StreamController bits and the Steam shader-thread bump used to live in the
# shared `homeManager/david.nix`, which meant every machine that imported it
# (laptop, kodi-as-desktop, …) got StreamController autostart and Steam
# tweaks even when no Stream Deck was present. Behind a custom option now.

{ lib, pkgs, config, ... }:
let
  cfg = config.custom.streamcontroller;
in {
  options.custom.streamcontroller = {
    enable = lib.mkEnableOption "StreamController flatpak autostart + Stream Deck overrides";
  };

  config = lib.mkIf (cfg.enable) { 
    home.file.".local/share/flatpak/overrides/com.core447.StreamController".text = ''
      [Context]
      filesystems=/run/user/1000;
    '';

    home.file.".config/autostart/StreamController.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=StreamController
      Exec=flatpak run com.core447.StreamController -b
    '';
  };

}
