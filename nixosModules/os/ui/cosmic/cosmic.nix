{ lib, pkgs, config, ... }:
with lib;                      
let
  # Shorter name to access final settings a 
  # user of hello.nix module HAS ACTUALLY SET.
  # cfg is a typical convention.
  cfg = config.services.custom.cosmic;
in {
  # Declare what settings a user of this "hello.nix" module CAN SET.
  options.services.custom = {
  
    cosmic = {
      enable = mkEnableOption "Use gnome";
    };

    cosmic.extensions = {
      enable = mkEnableOption "Add gnome Extensions";
    };

    cosmic.strip = {
      enable = mkEnableOption "Strip most default apps";
    };

    cosmic.disable = {
      hibernate = mkEnableOption "Strip most default apps";
    };


  };
  # Define what other settings, services and resources should be active IF
  # a user of this "hello.nix" module ENABLED this module 
  # by setting "services.hello.enable = true;".
  config = mkIf cfg.enable {

    # Enable the COSMIC login manager
    services.displayManager.cosmic-greeter.enable = true;

    # Enable the COSMIC desktop environment
    services.desktopManager.cosmic.enable = true;


    systemd.targets = mkIf (cfg.disable.hibernate == true ) {

     # sleep.enable = false;
      suspend.enable = false;
      hibernate.enable = false;
      hybrid-sleep.enable = false;

    };




    #environment.cosmic.excludePackages = with pkgs; mkIf (cfg.strip.enable == true ) [
    ## baobab      # disk usage analyzer
    #  cheese      # photo booth
    ## eog         # image viewer
    #  epiphany    # web browser
    ## gedit       # text editor
    #  simple-scan # document scanner
    #  totem       # video player
    #  yelp        # help viewer
    #  evince      # document viewer
    ## file-roller # archive manager
    #  geary       # email client
    #  seahorse    # password manager
#
    #  # these should be self explanatory
    #  gnome-calculator
    #  gnome-calendar 
    #  gnome-characters
    #  gnome-clocks
    #  gnome-contacts
    #  gnome-font-viewer
    #  gnome-logs
    #  gnome-maps
    #  gnome-music 
    #  gnome-photos
    ## gnome-screenshot
    ## gnome-system-monitor
    #  gnome-weather
    ## gnome-disk-utility
    #  gnome-connections
    #];

  };
}