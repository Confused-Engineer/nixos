{ lib, pkgs, config, ... }:
with lib;                      
let
  # Shorter name to access final settings a 
  # user of hello.nix module HAS ACTUALLY SET.
  # cfg is a typical convention.
  cfg = config.services.custom.gnome;
in {
  # Declare what settings a user of this "hello.nix" module CAN SET.
  options.services.custom = {
  
    gnome = {
      enable = mkEnableOption "Use gnome";
    };

    gnome.extensions = {
      enable = mkEnableOption "Add gnome Extensions";
    };

    gnome.strip = {
      enable = mkEnableOption "Strip most default apps";
    };

    gnome.disable = {
      hibernate = mkEnableOption "Strip most default apps";
    };


  };
  # Define what other settings, services and resources should be active IF
  # a user of this "hello.nix" module ENABLED this module 
  # by setting "services.hello.enable = true;".
  config = mkIf cfg.enable {

    services.xserver = {
      # Enable the X11 windowing system.
      enable = true;
      # Enable the GNOME Desktop Environment.
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
      excludePackages = [ pkgs.xterm ];

    };




    systemd.targets = mkIf (cfg.disable.hibernate == true ) {

     # sleep.enable = false;
      suspend.enable = false;
      hibernate.enable = false;
      hybrid-sleep.enable = false;

    };


    environment.systemPackages = with pkgs.gnomeExtensions; mkIf (cfg.extensions.enable == true ) [
      dash-to-dock
      tray-icons-reloaded
    ];





    environment.gnome.excludePackages = with pkgs; mkIf (cfg.strip.enable == true ) [
    # baobab      # disk usage analyzer
      cheese      # photo booth
    # eog         # image viewer
      epiphany    # web browser
    # gedit       # text editor
      simple-scan # document scanner
      totem       # video player
      yelp        # help viewer
      evince      # document viewer
    # file-roller # archive manager
      geary       # email client
      seahorse    # password manager

      # these should be self explanatory
      gnome-calculator
      gnome-calendar 
      gnome-characters
      gnome-clocks
      gnome-contacts
      gnome-font-viewer
      gnome-logs
      gnome-maps
      gnome-music 
      gnome-photos
    # gnome-screenshot
    # gnome-system-monitor
      gnome-weather
    # gnome-disk-utility
      gnome-connections
      gnome-software
    ];

  };
}