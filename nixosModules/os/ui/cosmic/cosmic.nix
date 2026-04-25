{ lib, pkgs, config, ... }:                   
let

  cfg = config.custom.os.ui.cosmic;
in {

  options.custom.os.ui = {
  
    cosmic = {
      enable = lib.mkEnableOption "Use gnome";
    };

    cosmic.strip = {
      enable = lib.mkEnableOption "Strip most default apps";
    };

    cosmic.nvidiaFix = {
      hibernate = lib.mkEnableOption "Fix Hibernate with Nvidia GPU";
    };


  };

  config = lib.mkIf cfg.enable {

    # Enable the COSMIC login manager
    services.displayManager.cosmic-greeter.enable = true;

    # Enable the COSMIC desktop environment
    services.desktopManager.cosmic.enable = true;

    systemd = lib.mkIf cfg.nvidiaFix.hibernate {
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


    environment.cosmic.excludePackages = with pkgs; lib.mkIf cfg.strip.enable [
      cosmic-store
    ];



  };
}