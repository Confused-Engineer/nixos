{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./../../nixosModules
    ./../baseline.nix
  ];

  custom = {
    apps = {
      steam.enable         = false;
      steam.systemd.enable = true;

      flatpaks = {
        enable = true;
        update = true;
        desiredFlatpaks = [
          "com.github.tchx84.Flatseal"
          "com.bambulab.BambuStudio"
          "com.plexamp.Plexamp"
        ];
      };

      browsers.firefox = {
        enable   = true;
        privacy  = "strict";
        homepage = "https://hp.int.a5f.org/";
      };
    };

    hardware.controllers.xbox.enable = true;

    boot = {
      enable           = true;
      fancy.enable     = true;
      fancy.secureBoot = true;
      systemd          = false;
    };

    os.ui.cosmic = {
      enable              = true;
      strip.enable        = true;
      nvidiaFix.hibernate = false;
    };

    systemd = {
      system-api.enable    = false;
      shizuku-linux.enable = false;
    };
  };

  specialisation.lid-no-sleep = {
    inheritParentConfig = true;
    configuration = {
      services.logind.settings.Login = {
        HandleLidSwitchDocked        = "ignore";
        HandleLidSwitchExternalPower = "ignore";
      };
    };
  };

  networking.hostName = "laptop";

  services.mullvad-vpn.enable  = true;
  services.mullvad-vpn.package = pkgs.mullvad-vpn;
  programs.kdeconnect.enable   = true;

  services.logind.settings.Login.HandleLidSwitch = "hibernate";
  services.power-profiles-daemon.enable          = true;
  powerManagement.enable                         = true;

  hardware.graphics.extraPackages = with pkgs; [
    intel-vaapi-driver
    intel-media-driver
  ];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.firewall = {
    allowedTCPPorts = [ 8080 ];
    allowedUDPPorts = [ 8080 ];
  };

  system.stateVersion = "25.11";
}
