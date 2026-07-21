# desktop — unstable nixpkgs, home-manager, both binary caches.
# Everything host-specific for desktop lives here; shared behaviour comes from
# the named modules composed in the `modules` list below.
{ config, inputs, ... }:
let
  nixos = config.flake.modules.nixos;
in
{
  flake.nixosConfigurations.desktop = inputs.nixpkgs-unstable.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      # Shared, dendritic
      nixos.base
      nixos.common
      nixos.baseline
      nixos.custom
      nixos.binaryCache
      nixos.cudaCache
      nixos.homeManager

      # Host hardware / disks
      ../../machines/desktop/hardware-configuration.nix
      ../../machines/desktop/data-mounts.nix

      # Host-specific config
      (
        { pkgs, ... }:
        {
          custom = {
            apps = {
              steam.enable = true;

              flatpaks = {
                enable = true;
                update = true;
                desiredFlatpaks = [
                  "com.github.tchx84.Flatseal"
                  "com.usebottles.bottles"
                  "com.bambulab.BambuStudio"
                  "org.freecad.FreeCAD"
                  "com.plexamp.Plexamp"
                  "com.core447.StreamController"
                ];
              };

              browsers.firefox = {
                enable = true;
                disableAccounts = false;
                privacy = "strict";
                homepage = "https://hp.int.a5f.org/";
              };
            };

            hardware.gpu.nvidia.enable = true;
            hardware.gpu.lact.enable = true;
            hardware.controllers.xbox.enable = true;

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
              system-api.enable = true;
              shizuku-linux.enable = false;
            };
          };

          networking.hostName = "desktop";

          boot.kernelModules = [ "ntsync" ];
          boot.kernelPackages = pkgs.linuxPackages_zen;

          programs.kdeconnect.enable = true;

          programs.gamemode = {
            enable = true;
            settings = {
              general = {
                renice = 10;
                inhibit_screensaver = 1;
              };
              cpu.governor = "performance";
              gpu = {
                apply_gpu_optimisations = "accept-responsibility";
                gpu_device = 0;
                nv_powermizer_mode = 1;
              };
            };
          };
          hardware.openrazer.enable = true;

          hardware.nvidia-container-toolkit.enable = true;
          virtualisation.docker = {
            enable = true;
          };

          environment.systemPackages = with pkgs; [
            heroic
            protonup-qt
            r2modman
            polychromatic
            openrazer-daemon
            gnome-system-monitor
            easyeffects
            vintagestory
            winboat

            stable.pcsx2
            stable.rpcs3
            stable.dolphin-emu
          ];

          system.stateVersion = "26.05";
        }
      )

    ];
  };
}
