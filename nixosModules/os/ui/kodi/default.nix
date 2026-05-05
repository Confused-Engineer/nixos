{ lib, pkgs, config, ... }:
let
  cfg = config.custom.os.ui.kodi;
in {
  options.custom.os.ui.kodi = {
    enable = lib.mkEnableOption "Kodi as the primary desktop session";
  };

  config = lib.mkIf cfg.enable {
    services.xserver = {
      enable                              = true;
      desktopManager.kodi.enable          = true;
      desktopManager.kodi.package         = pkgs.kodi.withPackages (kodiPkgs: with kodiPkgs; [
        jellyfin
        inputstream-adaptive
        pvr-iptvsimple
      ]);
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
    users.extraUsers.kodi.isNormalUser     = true;

    networking.firewall = {
      allowedTCPPorts = [ 22 8080 ];
      allowedUDPPorts = [ 8080 ];
    };

    services.logind.settings.Login.IdleAction = "ignore";

    systemd.targets = {
      sleep.enable       = false;
      suspend.enable     = false;
      hibernate.enable   = false;
      hybridSleep.enable = false;
    };
  };
}
