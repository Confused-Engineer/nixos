{
  flake.modules.nixos.custom =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.custom.apps.steam;
    in
    {
      options.custom.apps.steam = {
        enable = lib.mkEnableOption "Steam";
      };

      config = lib.mkIf cfg.enable {
        programs.steam = {
          enable = true;
          remotePlay.openFirewall = true;
          dedicatedServer.openFirewall = true;
          localNetworkGameTransfers.openFirewall = true;
          extraCompatPackages = [ pkgs.proton-ge-bin ];
        };
      };
    };
}
