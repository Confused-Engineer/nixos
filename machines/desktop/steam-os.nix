{ config, lib, pkgs, ... }:
let
  ext4DataMount = uuid: {
    device = "/dev/disk/by-uuid/${uuid}";
    fsType = "ext4";
    options = [ "defaults" "users" "nofail" "exec" ];
  };

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
  config = {
    specialisation = {
      SteamOS = {
        inheritParentConfig = false;
        configuration = {
          system.nixos.tags = [ "SteamOS" ];

          imports = [
            ./hardware-configuration.nix
            ./../../nixosModules
            ./../baseline.nix
          ];

          custom = {

            hardware.gpu.nvidia.enable = true;
            hardware.controllers.xbox.enable = true;
            hardware.gpu.lact.enable = true;

            boot = {
              enable = true;
              fancy.enable = true;
              fancy.secureBoot = true;
              systemd = false;
            };


          };


          programs.steam = {
            enable = true;
            remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
            dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
            localNetworkGameTransfers.openFirewall = true;
            extraCompatPackages = with pkgs; [ proton-ge-bin ];
            gamescopeSession = {
              enable = true;
              #args = [
              #  #"--prefer-output DP-5"
              #  #"--output-width 1920"
              #  #"--output-height 1080"
              #  #"--framerate-limit 60"
              #  "--fullscreen"
              #  "--steam"
              #];
              #env = {
              #  # Force Steam into Big Picture mode under Wayland/gamescope
              #  STEAM_FORCE_DESKTOPUI_SCALING = "1";
              #  STEAM_USE_DYNAMIC_VRS = "1";
              #  # Hint Steam/Qt apps to prefer Wayland
              #  QT_QPA_PLATFORM = "wayland";
              #  MOZ_ENABLE_WAYLAND = "1";
              #  NIXOS_OZONE_WL = "1";
              #};
            };
          };
          programs.gamescope = {
            enable = true;
            capSysNice = true;
          };

          programs.xwayland.enable = true;
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

          systemd.services."getty@tty1".enable = false;
          systemd.services."autovt@tty1".enable = false;
          systemd.services.greetd = {
            after = [
              "systemd-user-sessions.service"
              "systemd-logind.service"
              "multi-user.target"
              "plymouth-quit.service"
            ];
            wants = [
              "systemd-logind.service"
            ];
            requires = [
              "multi-user.target"
            ];
            serviceConfig = {
              # Small grace period so logind + udev + DRM are fully
              # quiescent before gamescope claims the seat.
              ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
            };
          };
          
          networking.hostName = "desktop";

          boot.kernelModules = [ "ntsync" ];
          boot.kernelParams = [ "nvidia-drm.modeset=1" "nvidia-drm.fbdev=1" ];

          environment.systemPackages = with pkgs; [
            heroic
            protonup-qt
            r2modman
            polychromatic
            openrazer-daemon

            stable.pcsx2
            stable.rpcs3
            stable.dolphin-emu

          ];

          hardware.openrazer.enable = true;

          system.stateVersion = "25.11";

          fileSystems."/media/Games" = ext4DataMount "1c39032b-b81a-410d-9d7f-4a9ae60073d4";
          fileSystems."/media/Extra01" = ext4DataMount "8c36d5a0-4afc-4bea-95be-6da718b570f8";
          fileSystems."/media/Extra02" = ext4DataMount "c3c0b3cb-2f63-47aa-b388-362bac34c7fa";
        };
      };
    };
  };
}
