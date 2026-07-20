# StreamController flatpak autostart + Stream Deck overrides. Gated so only the
# machine with a Stream Deck (desktop) autostarts it.
{
  flake.modules.homeManager.custom =
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
    };
}
