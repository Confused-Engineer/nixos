{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./../../nixosModules
  ];

  custom = {

    apps = {
      steam.enable = true;

      flatpak = {
        enable = true;
        update = true;
        desiredFlatpaks = [
          "com.github.tchx84.Flatseal"
          "com.bambulab.BambuStudio"
          "com.plexamp.Plexamp"
        ];
      };

      firefox = {
        enable = true;
        privacy = "strict";
        homepage = "https://hp.int.a5f.org/";
      };
    };

    hardware.controller-xbox.enable = true;

    os = {
      de-cosmic = {
        enable = true;
        strip.enable = true;
        nvidiaFix.hibernate = false;
      };
      boot = {
        enable = true;
        fancy.enable = true;
        fancy.secureBoot = true;
        systemd = false;
      };
      settings-common.enable = true;
      settings-baseline.enable = true;
      gc.enable = true;
    };

    systemd = {
      system-api.enable = false;
      shizuku-linux.enable = false;
    };
  };

  specialisation.lid-no-sleep = {
    inheritParentConfig = true;
    configuration = {
      services.logind.settings.Login = {
        HandleLidSwitchDocked = "ignore";
        HandleLidSwitchExternalPower = "ignore";
      };
    };
  };

  networking.hostName = "laptop";

  services.mullvad-vpn.enable = true;
  services.mullvad-vpn.gui.enable = true;
  programs.kdeconnect.enable = true;

  services.logind.settings.Login.HandleLidSwitch = "hibernate";
  services.power-profiles-daemon.enable = true;
  powerManagement.enable = true;

  # Battery/power optimizations for 11th-gen Tiger Lake (i5-1135G7)
  services.thermald.enable = true; # Intel thermal management daemon
  powerManagement.powertop.enable = true; # auto-tune USB/PCIe/SATA power at boot

  networking.networkmanager.wifi.powersave = true;

  boot.kernelParams = [
    "i915.enable_psr=1" # Panel Self Refresh — cuts display power draw
    "i915.enable_fbc=1" # Framebuffer Compression — reduces memory bandwidth
    "mem_sleep_default=deep" # Prefer S3 deep sleep over s2idle for suspend
  ];

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
