{
  config,
  lib,
  pkgs,
  ...
}:
let
  steamSession = pkgs.writeShellScript "steam-gamescope-session" ''
    exec > /tmp/gamescope-session.log 2>&1
    set -x

    # NVIDIA-specific: wlroots needs the Vulkan renderer; GLES hangs.
    export WLR_RENDERER=vulkan
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export GBM_BACKEND=nvidia-drm
    export __GL_GSYNC_ALLOWED=1
    export __GL_VRR_ALLOWED=1

    # Wayland hints for Steam and child apps.
    export QT_QPA_PLATFORM=wayland
    export MOZ_ENABLE_WAYLAND=1
    export NIXOS_OZONE_WL=1
    export STEAM_FORCE_DESKTOPUI_SCALING=1

    exec ${pkgs.gamescope}/bin/gamescope \
      --prefer-output DP-5 \
      --fullscreen \
      --steam \
      -- ${pkgs.steam}/bin/steam -tenfoot -pipewire-dmabuf
  '';
in
{
  specialisation.SteamOS = {
    inheritParentConfig = false;
    configuration = {
      imports = [
        ./hardware-configuration.nix
        ./../../nixosModules
        ./../baseline.nix
        ./data-mounts.nix
      ];

      system.nixos.tags = [ "SteamOS" ];

      custom = {
        hardware.gpu.nvidia.enable = true;
        hardware.gpu.lact.enable = true;
        hardware.controllers.xbox.enable = true;

        boot = {
          enable = true;
          fancy.enable = true;
          fancy.secureBoot = true;
          systemd = false;
        };
      };

      programs = {
        xwayland.enable = true;
        steam = {
          enable = true;
          remotePlay.openFirewall = true;
          dedicatedServer.openFirewall = true;
          localNetworkGameTransfers.openFirewall = true;
          extraCompatPackages = [ pkgs.proton-ge-bin ];
          gamescopeSession.enable = true;
        };
        gamescope = {
          enable = true;
          capSysNice = true;
        };
      };

      services.greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session --cmd ${steamSession}";
            user = "greeter";
          };
          initial_session = {
            command = "${steamSession}";
            user = "david";
          };
        };
      };

      systemd.services = {
        "getty@tty1".enable = false;
        "autovt@tty1".enable = false;
        greetd = {
          after = [
            "systemd-user-sessions.service"
            "systemd-logind.service"
            "multi-user.target"
            "plymouth-quit.service"
          ];
          wants = [ "systemd-logind.service" ];
          requires = [ "multi-user.target" ];
          serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
        };
      };

      networking.hostName = "desktop";
      boot.kernelModules = [ "ntsync" ];
      boot.kernelPackages = pkgs.linuxPackages_latest;
      hardware.openrazer.enable = true;
      nixpkgs.config.allowUnfree = true;

      environment.systemPackages = with pkgs; [
        heroic
        r2modman
        openrazer-daemon
        stable.pcsx2
        stable.rpcs3
        stable.dolphin-emu
      ];

      system.stateVersion = "25.11";
    };
  };
}
