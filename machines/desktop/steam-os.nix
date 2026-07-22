# SteamOS-style session for g5-5587. A boot-menu specialisation that inherits
# the whole host config (NVIDIA + PRIME, xbox controllers, steam, boot) but
# drops COSMIC and autologins david straight into Steam Big Picture running in
# gamescope — no DE/WM. Default boot stays the normal COSMIC laptop; pick the
# "steamos" entry at the systemd-boot menu for the console experience.
{ pkgs, lib, ... }:
let
  steamSession = pkgs.writeShellScript "steam-gamescope-session" ''
    exec > /tmp/gamescope-session.log 2>&1
    set -x

    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export GBM_BACKEND=nvidia-drm
    export __GL_GSYNC_ALLOWED=1
    export __GL_VRR_ALLOWED=1

    export QT_QPA_PLATFORM=wayland
    export NIXOS_OZONE_WL=1
    export STEAM_FORCE_DESKTOPUI_SCALING=1

    exec ${pkgs.gamescope}/bin/gamescope \
      --prefer-output DP-3 \
      --fullscreen \
      --steam \
      -- ${pkgs.steam}/bin/steam -tenfoot -pipewire-dmabuf
  '';
in
{
  specialisation.steamos.configuration = {
    system.nixos.tags = [ "steamos" ];

    custom.os.ui.cosmic.enable = lib.mkForce false;

    programs.xwayland.enable = true;
    programs.gamescope = {
      enable = true;
      capSysNice = true;
    };
    programs.steam.gamescopeSession.enable = true;

    services.greetd = {
      enable = true;
      settings = {
        # Autologin into Steam on boot; fall back to a greeter on logout.
        initial_session = {
          command = "${steamSession}";
          user = "david";
        };
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd ${steamSession}";
          user = "greeter";
        };
      };
    };

    systemd.services."getty@tty1".enable = false;
    systemd.services."autovt@tty1".enable = false;
  };
}
