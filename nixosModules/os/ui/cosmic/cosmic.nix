{ lib, pkgs, config, ... }:
with lib;                      
let
  # Shorter name to access final settings a 
  # user of hello.nix module HAS ACTUALLY SET.
  # cfg is a typical convention.
  cfg = config.custom.os.ui.cosmic;
in {
  # Declare what settings a user of this "hello.nix" module CAN SET.
  options.custom.os.ui = {
  
    cosmic = {
      enable = mkEnableOption "Use gnome";
    };

    cosmic.strip = {
      enable = mkEnableOption "Strip most default apps";
    };

    cosmic.nvidiaFix = {
      hibernate = mkEnableOption "Fix Hibernate with Nvidia GPU";
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

    systemd = mkIf (cfg.nvidiaFix.hibernate == true ) {
      services."cosmic-suspend" = {
        description = "suspend cosmic desktop";
        before = [
          "systemd-suspend.service" 
          "systemd-hibernate.service"
          "nvidia-suspend.service"
          "nvidia-hibernate.service"
        ];
        wantedBy = [
          "systemd-suspend.service"
          "systemd-hibernate.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = ''${pkgs.procps}/bin/pkill -f -STOP ${pkgs.cosmic-osd}/bin/cosmic-osd'';
        };
      };
      services."cosmic-resume" = {
        description = "resume cosmic desktop";
        after = [
          "systemd-suspend.service" 
          "systemd-hibernate.service"
          "nvidia-resume.service"
        ];
        wantedBy = [
          "systemd-suspend.service"
          "systemd-hibernate.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = ''${pkgs.procps}/bin/pkill -f -CONT ${pkgs.cosmic-osd}/bin/cosmic-osd'';
        };
      };
    };


    environment.cosmic.excludePackages = with pkgs; mkIf (cfg.strip.enable == true ) [
      cosmic-store
    ];



  };
}