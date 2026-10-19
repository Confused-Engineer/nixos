# StreamController (Stream Deck) autostart, home-manager side. Only the
# desktop has a Stream Deck, so only modules/hosts/desktop/home.nix imports
# it (the package itself is in that host's systemPackages).
#
# Migrated off the Flatpak (com.core447.StreamController) to the native
# nixpkgs package: the Flatpak is no longer in desiredFlatpaks and its
# autostart entry was failing every login since it's not installed. The
# native app's per-plugin venvs also need rebuilding after this switch —
# any venv created while the Flatpak was active copies its FHS-linked
# Python interpreter, which can't execute outside that sandbox on NixOS.
{
  flake.modules.homeManager.streamcontroller =
    { pkgs, ... }:
    {
      home.file.".config/autostart/StreamController.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=StreamController
        Exec=${pkgs.streamcontroller}/bin/streamcontroller -b
      '';
    };
}
