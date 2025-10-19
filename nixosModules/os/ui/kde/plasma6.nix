{ lib, pkgs, config, ... }:
with lib;                      
let
  # Shorter name to access final settings a 
  # user of hello.nix module HAS ACTUALLY SET.
  # cfg is a typical convention.
  cfg = config.custom.os.ui.kde;
in {
  # Declare what settings a user of this "hello.nix" module CAN SET.
  options.custom.os.ui = {
  
    kde = {
      enable = mkEnableOption "Use KDE Plasma 6";
    };

    kde.strip = {
      enable = mkEnableOption "Strip most default apps";
    };

  };
  # Define what other settings, services and resources should be active IF
  # a user of this "hello.nix" module ENABLED this module 
  # by setting "services.hello.enable = true;".
  config = mkIf cfg.enable {


    services.xserver.enable = true; # optional
    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.wayland.enable = true;
    services.desktopManager.plasma6.enable = true;
    excludePackages = [ pkgs.xterm ];

    environment.plasma6.excludePackages = with pkgs; mkIf (cfg.strip.enable == true ) [
      kdePackages.elisa # Simple music player aiming to provide a nice experience for its users
      kdePackages.kdepim-runtime # Akonadi agents and resources
      kdePackages.kmahjongg # KMahjongg is a tile matching game for one or two players
      kdePackages.kmines # KMines is the classic Minesweeper game
      kdePackages.konversation # User-friendly and fully-featured IRC client
      kdePackages.kpat # KPatience offers a selection of solitaire card games
      kdePackages.ksudoku # KSudoku is a logic-based symbol placement puzzle
      kdePackages.ktorrent # Powerful BitTorrent client
      mpv
    ];

  };
}