{ config, lib, pkgs, ... }:

{
  imports =
    [
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
          "at.vintagestory.VintageStory"
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



  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  networking.hostName = "lat9430";
  networking.networkmanager.enable = true;

  time.timeZone = "America/New_York";

  services.getty.autologinUser = "david";
  boot.kernelParams = [
    "i915.enable_psr=0"
  ];
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };

  users.users.david = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
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
    vim
    wget
    foot
    kitty
    waybar
    git
    hyprpaper
    brightnessctl
    iio-hyprland
    jq
    pavucontrol
  ];

#  services.logind.settings.Login.HandleLidSwitch = "hibernate";
 services.logind.lidSwitch = "hibernate";

  hardware.sensor.iio.enable = true;

#  programs.dconf.enable = true;

#  programs.dconf.profiles.david = {
#    databases = [{
#      lockAll = true;
#      settings = {
#        "org/gnome/desktop/interface" = {
#          color-scheme = "prefer-dark";
#          gtk-theme = "adw-gtk";
#          clock-format = "12h";
#          clock-show-weekday = true;
#        };
#      };
#    }];
#  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "25.05";

}

