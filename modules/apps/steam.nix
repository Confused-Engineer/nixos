# Steam. Two halves of one feature:
#   nixos.steam        — the system-wide Steam install (+ Proton-GE)
#   homeManager.steam  — per-user Steam tweaks; set `custom.steam.shaderThreads`
{
  flake.modules.nixos.steam =
    { pkgs, ... }:
    {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
        extraCompatPackages = [ pkgs.proton-ge-bin ];
      };
    };

  flake.modules.homeManager.steam =
    { lib, config, ... }:
    {
      options.custom.steam.shaderThreads = lib.mkOption {
        type = lib.types.int;
        description = "Override Steam's shader background processing thread count.";
      };

      config.home.file.".local/share/Steam/steam_dev.cfg".text = ''
        unShaderBackgroundProcessingThreads ${toString config.custom.steam.shaderThreads}
      '';
    };
}
