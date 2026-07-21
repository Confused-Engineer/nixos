# g5-5587 — Dell G5 5587 (2018), i7 + GTX 1060 Optimus laptop.
# Unstable nixpkgs, home-manager, steam. Pascal dGPU → closed driver
# (open = false) with PRIME offload against the Intel iGPU.
{ config, inputs, ... }:
let
  nixos = config.flake.modules.nixos;
in
{
  flake.nixosConfigurations.g5-5587 = inputs.nixpkgs-unstable.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      nixos.base
      nixos.common
      nixos.baseline
      nixos.custom
      nixos.binaryCache
      nixos.cudaCache
      nixos.homeManager

      ../../machines/g5-5587/hardware-configuration.nix

      (
        { pkgs, lib, ... }:
        let
          # Boots straight into Steam Big Picture inside gamescope — no DE/WM.
          steamSession = pkgs.writeShellScript "steam-gamescope-session" ''
            exec > /tmp/gamescope-session.log 2>&1
            set -x

            # ponytail: GPU calibration knob — untested on this Optimus box.
            # Default: gamescope compositor runs on the Intel iGPU (it drives the
            # panel) and games offload to the GTX 1060 via PRIME. If Big Picture
            # is slow or misrenders, force the whole session onto NVIDIA the way
            # the desktop does: WLR_RENDERER=vulkan, GBM_BACKEND=nvidia-drm.
            export __NV_PRIME_RENDER_OFFLOAD=1
            export __GLX_VENDOR_LIBRARY_NAME=nvidia
            export __VK_LAYER_NV_optimus=NVIDIA_only
            export __GL_GSYNC_ALLOWED=1
            export __GL_VRR_ALLOWED=1

            export QT_QPA_PLATFORM=wayland
            export NIXOS_OZONE_WL=1
            export STEAM_FORCE_DESKTOPUI_SCALING=1

            exec ${pkgs.gamescope}/bin/gamescope \
              --fullscreen \
              --steam \
              -- ${pkgs.steam}/bin/steam -tenfoot -pipewire-dmabuf
          '';
        in
        {
          # SteamOS-style session. Inherits everything from the parent (nvidia +
          # PRIME, xbox controllers, steam, boot) but drops COSMIC and autologins
          # david straight into the gamescope Steam session via greetd.
          # Pick it at the systemd-boot menu ("steamos" entry).
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

          custom = {
            apps = {
              steam.enable = true;

              browsers.firefox = {
                enable = true;
                privacy = "strict";
                homepage = "https://hp.int.a5f.org/";
              };
            };

            hardware.gpu.nvidia = {
              enable = true;
              open = false; # Pascal (GTX 1060) — open modules unsupported
              prime.enable = true;
              # ponytail: placeholder bus IDs — set from `lspci | grep -E 'VGA|3D'`.
              # G5 5587 is typically intel 00:02.0, nvidia 01:00.0 (the defaults),
              # but confirm on the box before trusting them.
            };

            boot = {
              enable = true;
              fancy.enable = true;
              fancy.secureBoot = true;
              systemd = false;
            };

            os.ui.cosmic = {
              enable = true;
              strip.enable = true;
              nvidiaFix.hibernate = false;
            };

            systemd = {
              system-api.enable = false;
              shizuku-linux.enable = false;
            };
          };

          networking.hostName = "g5-5587";

          services.power-profiles-daemon.enable = true;
          powerManagement.enable = true;
          services.thermald.enable = true;

          hardware.graphics.extraPackages = with pkgs; [
            intel-vaapi-driver
            intel-media-driver
          ];
          boot.kernelPackages = pkgs.linuxPackages_latest;

          system.stateVersion = "25.11";
        }
      )
    ];
  };
}
