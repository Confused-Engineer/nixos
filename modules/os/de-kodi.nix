# Kodi as the primary desktop session (HTPC). Like every de-* aspect,
# keeps an `enable` option (default on) so specialisations can switch it
# off — the kodi host's `desktop` specialisation does exactly that.
{
  flake.modules.nixos.de-kodi =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      options.custom.de-kodi.enable = lib.mkEnableOption "Kodi as the primary desktop session" // {
        default = true;
      };

      config = lib.mkIf config.custom.de-kodi.enable {
        services.xserver = {
          enable = true;
          desktopManager.kodi.enable = true;
          desktopManager.kodi.package = pkgs.kodi.withPackages (
            kodiPkgs: with kodiPkgs; [
              jellyfin
              inputstream-adaptive
              pvr-iptvsimple
            ]
          );
          displayManager.lightdm.greeter.enable = false;
          # Don't blank or sleep an HTPC.
          serverFlagsSection = ''
            Option "BlankTime"   "0"
            Option "StandbyTime" "0"
            Option "SuspendTime" "0"
            Option "OffTime"     "0"
          '';
        };

        services.displayManager.autoLogin.user = "kodi";
        users.extraUsers.kodi.isNormalUser = true;

        networking.firewall = {
          allowedTCPPorts = [
            22
            8080
          ];
          allowedUDPPorts = [ 8080 ];
        };

        services.logind.settings.Login.IdleAction = "ignore";

        systemd.targets = {
          sleep.enable = false;
          suspend.enable = false;
          hibernate.enable = false;
          hybridSleep.enable = false;
        };
      };
    };
}
