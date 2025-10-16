# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./../../nixosModules
    ];

  custom = {
    apps = {
      flatpaks = {
        enable = true;
        update = true;
        desiredFlatpaks = [
          "org.onlyoffice.desktopeditors"
          "com.github.tchx84.Flatseal"
          "com.usebottles.bottles"
          "com.bambulab.BambuStudio"
        ];
      };

      browsers.firefox = {
        enable = true;
        DisableFirefoxAccounts = false;
        privacy = "strict";
        homepage = "https://hp.a5f.org/";
      };
    };

    hardware.controllers.xbox.enable = true;
    
  };


  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "lat9430"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "America/New_York";

  boot.kernelParams = [
    "i915.enable_psr=0"
  ];
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };


#  services.getty.autologinUser = "david";
  users.users.david = {
    isNormalUser = true;
    extraGroups = [ "wheel" "power"];
    packages = with pkgs; [
      tree
    ];
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    # Git tracking
    git 

    # Better CLI
    zsh
    zsh-completions
    kitty

    # Top Bar
    waybar

    # Network Applet
    networkmanagerapplet

    # Logout Menu
    wlogout

    # Hyprland idle and lock tools
    hypridle
    hyprlock
    
    # Brightness control
    brightnessctl

    # Orientation and Hardware support
    iio-hyprland
    jq

    #Volume Controller
    pavucontrol

    # Wallpaper: waypaper frontend, hyprpaper backend
    hyprpaper
    waypaper

    # hyprland color picker
    hyprpicker

    # File Manager, allow openening any terminal, mounting network shares
    nautilus
    nautilus-open-any-terminal
    gnome.gvfs

    # Desktop Portal so apps can use filepickers, etc
    xdg-desktop-portal-hyprland
    xdg-desktop-portal


    # dock and appearance
    nwg-dock-hyprland
    nwg-look
  ];

  #  services.logind.settings.Login.HandleLidSwitch = "hibernate";
  services.logind.lidSwitch = "hibernate";

   hardware.sensor.iio.enable = true;

#  programs.dconf.enable = true;

  #programs.dconf.profiles.david = {
  #  databases = [{
  #    lockAll = true;
  #    settings = {
  #      "org/gnome/desktop/interface" = {
  #        color-scheme = "prefer-dark";
  #        gtk-theme = "adw-gtk";
  #        clock-format = "12h";
  #        clock-show-weekday = true;
  #      };
  #    };
  #  }];
  #};

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    fira-sans
    fira-code
    nerd-fonts.fira-code
    font-awesome
    material-design-icons
  ];

  systemd.services.fprintd = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "simple";
  };

  services.fprintd = {
    enable = true;
    package = pkgs.fprintd-tod;
    tod.enable = true;
    tod.driver = pkgs.libfprint-2-tod1-broadcom;
  };


  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "25.05";


}

