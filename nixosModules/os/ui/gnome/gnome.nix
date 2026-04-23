{ lib, pkgs, config, ... }:
                  
let
  # Shorter name to access final settings a 
  # user of hello.nix module HAS ACTUALLY SET.
  # cfg is a typical convention.
  cfg = config.custom.os.ui.gnome;
in {
  # Declare what settings a user of this "hello.nix" module CAN SET.
  options.custom.os.ui = {
  
    gnome = {
      enable = lib.mkEnableOption "Use gnome";
    };

    gnome.extensions = {
      enable = lib.mkEnableOption "Add gnome Extensions";
    };

    gnome.strip = {
      enable = lib.mkEnableOption "Strip most default apps";
    };

    gnome.nvidiaFix = {
      hibernate = lib.mkEnableOption "Fix Hibernate with Nvidia GPU";
    };

  };
  # Define what other settings, services and resources should be active IF
  # a user of this "hello.nix" module ENABLED this module 
  # by setting "services.hello.enable = true;".
  config = lib.mkIf cfg.enable {

    services.xserver = {
      # Enable the X11 windowing system.
      enable = true;
      # Enable the GNOME Desktop Environment.
      displayManager.gdm.enable = true;
      displayManager.gdm.autoSuspend = true;
      desktopManager.gnome.enable = true;
      excludePackages = [ pkgs.xterm ];

    };





    environment.systemPackages = with pkgs.gnomeExtensions; lib.mkIf (cfg.extensions.enable == true ) [
      dash-to-dock
      tray-icons-reloaded
    ];


    systemd = {
      services.copyGdmMonitorsXml = {
        description = "Copy monitors.xml to GDM config";
        after = [ "network.target" "systemd-user-sessions.service" "display-manager.service" ];
        serviceConfig = {
          ExecStart = "${pkgs.bash}/bin/bash -c 'echo \"Running copyGdmMonitorsXml service\" && mkdir -p /run/gdm/.config && echo \"Created /run/gdm/.config directory\" && [ \"/home/david/.config/monitors.xml\" -ef \"/run/gdm/.config/monitors.xml\" ] || cp /home/david/.config/monitors.xml /run/gdm/.config/monitors.xml && echo \"Copied monitors.xml to /run/gdm/.config/monitors.xml\" && chown gdm:gdm /run/gdm/.config/monitors.xml && echo \"Changed ownership of monitors.xml to gdm\"'";
          Type = "oneshot";
        };
        wantedBy = [ "multi-user.target" ];
      };

      services."gnome-suspend" = mkIf (cfg.nvidiaFix.hibernate == true ) {
        description = "suspend gnome shell";
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
          ExecStart = ''${pkgs.procps}/bin/pkill -f -STOP ${pkgs.gnome-shell}/bin/gnome-shell'';
        };
      };
      services."gnome-resume" = mkIf (cfg.nvidiaFix.hibernate == true ) {
        description = "resume gnome shell";
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
          ExecStart = ''${pkgs.procps}/bin/pkill -f -CONT ${pkgs.gnome-shell}/bin/gnome-shell'';
        };
      };
    };


    environment.gnome.excludePackages = with pkgs; lib.mkIf (cfg.strip.enable == true ) [
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