# LACT GPU control daemon.
{
  flake.modules.nixos.lact =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.lact ];

      systemd.services.lact = {
        enable = true;
        description = "LACT GPU control daemon";
        after = [ "multi-user.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig.ExecStart = "${pkgs.lact}/bin/lact daemon";
      };
    };
}
