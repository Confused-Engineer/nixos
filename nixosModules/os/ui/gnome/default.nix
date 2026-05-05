{ lib, pkgs, config, ... }:
let
  cfg     = config.custom.os.ui.gnome;
  helpers = import ./../../../../lib { inherit lib pkgs; };

  # Move the inline shell from a one-liner into a script so it's readable.
  copyMonitorsXml = pkgs.writeShellScript "copy-gdm-monitors-xml" ''
    set -e
    src=/home/david/.config/monitors.xml
    dst=/run/gdm/.config/monitors.xml
    if [ ! -e "$src" ]; then
      echo "copy-gdm-monitors-xml: $src missing, skipping"
      exit 0
    fi
    mkdir -p "$(dirname "$dst")"
    if [ "$src" -ef "$dst" ]; then
      exit 0
    fi
    cp "$src" "$dst"
    chown gdm:gdm "$dst"
    echo "copy-gdm-monitors-xml: refreshed $dst"
  '';
in {
  options.custom.os.ui.gnome = {
    enable              = lib.mkEnableOption "GNOME desktop";
    extensions.enable   = lib.mkEnableOption "GNOME extensions (dash-to-dock, tray-icons)";
    strip.enable        = lib.mkEnableOption "remove most default GNOME apps";
    nvidiaFix.hibernate = lib.mkEnableOption "STOP/CONT gnome-shell around suspend (NVIDIA hibernate fix)";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      services.xserver = {
        enable                       = true;
        displayManager.gdm.enable    = true;
        displayManager.gdm.autoSuspend = true;
        desktopManager.gnome.enable  = true;
        excludePackages              = [ pkgs.xterm ];
      };

      environment.systemPackages = lib.mkIf cfg.extensions.enable (with pkgs.gnomeExtensions; [
        dash-to-dock
        tray-icons-reloaded
      ]);

      systemd.services.copyGdmMonitorsXml = {
        description = "Copy david's monitors.xml into GDM's config";
        after       = [ "network.target" "systemd-user-sessions.service" "display-manager.service" ];
        wantedBy    = [ "multi-user.target" ];
        serviceConfig = {
          Type      = "oneshot";
          ExecStart = "${copyMonitorsXml}";
        };
      };

      environment.gnome.excludePackages = lib.mkIf cfg.strip.enable (with pkgs; [
        cheese
        epiphany
        simple-scan
        totem
        yelp
        evince
        geary
        seahorse
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
        gnome-weather
        gnome-connections
        gnome-software
      ]);
    }

    (lib.mkIf cfg.nvidiaFix.hibernate {
      systemd = helpers.mkNvidiaSuspendFix {
        name   = "gnome";
        binary = "${pkgs.gnome-shell}/bin/gnome-shell";
      };
    })
  ]);
}
