{ lib, pkgs, config, ... }:                     
let
  # Shorter name to access final settings a 
  # user of hello.nix module HAS ACTUALLY SET.
  # cfg is a typical convention.
  cfg = config.custom.os.ui.kodi;
in {
  # Declare what settings a user of this "hello.nix" module CAN SET.
  options.custom.os.ui = {
  
    kodi = {
      enable = lib.mkEnableOption "Enable Kodi Media Center";
    };

  };
  # Define what other settings, services and resources should be active IF
  # a user of this "hello.nix" module ENABLED this module 
  # by setting "services.hello.enable = true;".
  config = lib.mkIf cfg.enable {


    services.xserver.enable = true;
    services.xserver.desktopManager.kodi.enable = true;
    services.xserver.desktopManager.kodi.package = (pkgs.kodi.withPackages (kodiPkgs: with kodiPkgs; [
      jellyfin
      inputstream-adaptive
      pvr-iptvsimple
    ]));

    services.displayManager.autoLogin.user = "kodi";
    services.xserver.displayManager.lightdm.greeter.enable = false;
    users.extraUsers.kodi.isNormalUser = true;
    networking.firewall = {
      allowedTCPPorts = [ 22 8080 ];
      allowedUDPPorts = [ 8080 ];
    };
    
    services.logind.settings.Login = {
      IdleAction = "ignore";
    };
    systemd.targets.sleep.enable = false;
    systemd.targets.suspend.enable = false;
    systemd.targets.hibernate.enable = false;
    systemd.targets.hybridSleep.enable = false;


  };
}