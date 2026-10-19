# desktop — main PC: AMD CPU, NVIDIA (GA104) GPU, COSMIC, gaming.
# The rest of this host is split across the other files in this directory,
# each adding to `flake.modules.nixos.desktop`:
#   hardware.nix     generated hardware config
#   data-mounts.nix  extra data disks + TrueNAS share
#   steam-os.nix     `steamos` boot-menu specialisation
#   docker.nix       `docker` boot-menu specialisation
#   home.nix         desktop-only home-manager additions for david
{ inputs, self, ... }:
{
  flake.nixosConfigurations.desktop = inputs.nixpkgs-unstable.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ self.modules.nixos.desktop ];
  };

  flake.modules.nixos.desktop =
    { pkgs, ... }:
    {
      imports = with self.modules.nixos; [
        nixpkgs
        binary-cache
        home-manager

        firefox
        flatpak
        lact
        steam
        controller-xbox
        gpu-nvidia
        boot
        de-cosmic
        gc
        settings-common
        settings-baseline
        yubikey
        system-api
      ];

      custom = {
        flatpak = {
          update = true;
          desiredFlatpaks = [
            "com.github.tchx84.Flatseal"
            "com.usebottles.bottles"
            "com.bambulab.BambuStudio"
            "org.freecad.FreeCAD"
            "com.plexamp.Plexamp"
          ];
        };

        firefox = {
          disableAccounts = false;
          privacy = "strict";
          homepage = "https://hp.a5f.org/";
        };

        de-cosmic = {
          strip.enable = true;
          nvidiaFix.hibernate = false;
        };

        boot = {
          fancy.enable = true;
          fancy.secureBoot = true;
          systemd = false;
        };
      };

      networking.hostName = "desktop";

      boot.kernelModules = [ "ntsync" ];
      boot.kernelPackages = pkgs.linuxPackages_zen;
      # Disable auto suspend to prevent the momentary Xbox controller connection drops during play.
      boot.kernelParams = [ "btusb.enable_autosuspend=0" ];
      # Dont wait for network on boot, maybe boot faster?
      systemd.services.NetworkManager-wait-online.enable = false;

      programs.kdeconnect.enable = true;
      services.tailscale = {
        enable = true;

        # Declare the operator flag with your username
        extraUpFlags = [
          "--operator=david"
        ];
      };

      programs.gamemode = {
        enable = true;
        settings = {
          general = {
            renice = 10;
            inhibit_screensaver = 1;
          };
          cpu.governor = "performance";
          # gpu = {
          #   apply_gpu_optimisations = "accept-responsibility";
          #   gpu_device = 0;
          #   nv_powermizer_mode = 1;
          # };
        };
      };
      hardware.openrazer.enable = true;

      environment.systemPackages = with pkgs; [
        heroic
        protonup-qt
        r2modman
        polychromatic
        openrazer-daemon
        gnome-system-monitor
        easyeffects
        streamcontroller
        vintagestory

        stable.pcsx2
        stable.rpcs3
        stable.dolphin-emu
      ];

      system.stateVersion = "26.05";
    };
}
