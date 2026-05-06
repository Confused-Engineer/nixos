# StreamController bits and the Steam shader-thread bump used to live in the
# shared `homeManager/david.nix`, which meant every machine that imported it
# (laptop, kodi-as-desktop, …) got StreamController autostart and Steam
# tweaks even when no Stream Deck was present. Behind a custom option now.

{ lib, pkgs, config, ... }:
let
  cfg = config.custom.steam;
in {
  options.custom.steam = {
    steamShaderThreads = lib.mkOption {
      type        = lib.types.nullOr lib.types.int;
      default     = null;
      description = "Override Steam's shader background processing thread count. Null disables.";
    };
  };

  config = lib.mkIf (cfg.steamShaderThreads != null) 
  {

    home.file.".local/share/Steam/steam_dev.cfg".text = ''
      unShaderBackgroundProcessingThreads ${toString cfg.steamShaderThreads}
    '';
  };
}
