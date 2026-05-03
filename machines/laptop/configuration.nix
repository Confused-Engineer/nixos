# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
  [
    ./hardware-configuration.nix
    ./../../nixosModules
    ./../baseline.nix
  ];

  custom = {
    apps = {
      steam.enable = false; # Enable Steam
      steam.systemd.enable = true; # Start Steam on Login
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
        enable = true;
        privacy = "strict";
        homepage = "https://hp.int.a5f.org/";
      };
    };

    hardware.controllers.xbox.enable = true;

    boot = {
      enable = true;
      fancy.enable = true;
      fancy.secureBoot = true;
      systemd = false;
    };

    os = {
      ui = {
        cosmic = {
          enable = true; # Use gnome
          strip.enable = true;
          nvidiaFix.hibernate = false;
        };
      };
    };

    systemd = {
      system-api.enable = false; # Enable System API For Home Assistant
      shizuku-linux.enable = false; # Enable starting shizuku on android device plugin
    };
  };

  specialisation = {
    lid-no-sleep = {
      inheritParentConfig = true;
      configuration = {
        services.logind.settings.Login.HandleLidSwitchDocked = "ignore"; 
        services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore"; 
      };
    };
  };

  services.mullvad-vpn.enable = true;
  services.mullvad-vpn.package = pkgs.mullvad-vpn;
  programs.kdeconnect.enable = true;

  networking.hostName = "laptop"; # Define your hostname.

  environment.systemPackages = with pkgs; [

  ];

  services.logind.settings.Login.HandleLidSwitch = "hibernate";

  services.power-profiles-daemon.enable = true;
  powerManagement.enable = true;

  hardware.graphics.extraPackages = with pkgs; [ intel-vaapi-driver intel-media-driver ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  networking.firewall = {
    allowedTCPPorts = [ 8080 ];
    allowedUDPPorts = [ 8080 ];
  };
  # networking.firewall.enable = false;
  system.stateVersion = "25.11"; 

}
