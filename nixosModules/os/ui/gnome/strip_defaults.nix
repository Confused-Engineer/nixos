{ lib, pkgs, config, ... }:
with lib;                      
let
  # Shorter name to access final settings a 
  # user of hello.nix module HAS ACTUALLY SET.
  # cfg is a typical convention.
  cfg = config.services.custom.gnome.strip;
in {
  # Declare what settings a user of this "hello.nix" module CAN SET.
  options.services.custom.gnome = {
  
    strip = {
      enable = mkEnableOption "Strip default apps from gnome";
    };


  };
  # Define what other settings, services and resources should be active IF
  # a user of this "hello.nix" module ENABLED this module 
  # by setting "services.hello.enable = true;".
  config = mkIf cfg.enable {

    environment.gnome.excludePackages = with pkgs; [
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
    ];
  };
}