# StreamController bits and the Steam shader-thread bump used to live in the
# shared `homeManager/david.nix`, which meant every machine that imported it
# (laptop, kodi-as-desktop, …) got StreamController autostart and Steam
# tweaks even when no Stream Deck was present. Behind a custom option now.
#
# Migrated off the Flatpak (com.core447.StreamController) to the native
# nixpkgs package: the Flatpak is no longer in desiredFlatpaks and its
# autostart entry was failing every login since it's not installed. The
# native app's per-plugin venvs also need rebuilding after this switch —
# any venv created while the Flatpak was active copies its FHS-linked
# Python interpreter, which can't execute outside that sandbox on NixOS.

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.custom.streamcontroller;
in
{
  options.custom.streamcontroller = {
    enable = lib.mkEnableOption "StreamController native autostart + Stream Deck overrides";
  };

  config = lib.mkIf (cfg.enable) {
    home.file.".config/autostart/StreamController.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=StreamController
      Exec=${pkgs.streamcontroller}/bin/streamcontroller -b
    '';
  };

}
