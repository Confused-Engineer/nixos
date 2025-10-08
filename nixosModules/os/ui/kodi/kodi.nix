{ lib, pkgs, config, ... }:
with lib;                      
let
  # Shorter name to access final settings a 
  # user of hello.nix module HAS ACTUALLY SET.
  # cfg is a typical convention.
  cfg = config.custom.os.ui.kodi;
in {
  # Declare what settings a user of this "hello.nix" module CAN SET.
  options.custom.os.ui = {
  
    kodi = {
      enable = mkEnableOption "Use gnome";
    };

    kodi.user.kodi = {
      enable = mkEnableOption "Add gnome Extensions";
    };

    kodi.user.kodi.autologin = {
      enable = mkEnableOption "Strip most default apps";
    };

    kodi.lidswitch.disable = {
      enable = mkEnableOption "Strip most default apps";
    };


  };
  # Define what other settings, services and resources should be active IF
  # a user of this "hello.nix" module ENABLED this module 
  # by setting "services.hello.enable = true;".
  config = mkIf cfg.enable {


    services.xserver.enable = true;
    services.xserver.desktopManager.kodi.enable = true;
    services.displayManager.autoLogin.user = "kodi";
    services.xserver.displayManager.lightdm.greeter.enable = false;
    users.extraUsers.kodi.isNormalUser = true;
    networking.firewall = {
      allowedTCPPorts = [ 22 8080 ];
      allowedUDPPorts = [ 8080 ];
    };
    
    systemd.targets.sleep.enable = false;
    systemd.targets.suspend.enable = false;
    systemd.targets.hibernate.enable = false;
    systemd.targets.hybridSleep.enable = false;

  };
}