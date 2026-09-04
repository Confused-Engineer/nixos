{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./../../nixosModules
    ./data-mounts.nix
    ./steam-os.nix
  ];

  custom = {

    apps = {
      steam.enable = true;
      lact.enable = false;

      flatpak = {
        enable = true;
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
        enable = true;
        disableAccounts = false;
        privacy = "strict";
        homepage = "https://hp.a5f.org/";
      };
    };

    hardware.gpu-nvidia.enable = true;
    hardware.controller-xbox.enable = true;

    os = {
      de-cosmic = {
        enable = true;
        strip.enable = true;
        nvidiaFix.hibernate = false;
      };
      boot = {
        enable = true;
        fancy.enable = true;
        fancy.secureBoot = true;
        systemd = false;
      };
      settings-common.enable = true;
      settings-baseline.enable = true;
      gc.enable = true;
    };

    systemd = {
      system-api.enable = true;
      shizuku-linux.enable = false;
    };
  };

  networking.hostName = "desktop";

  boot.kernelModules = [ "ntsync" ];
  boot.kernelPackages = pkgs.linuxPackages_zen;
  # Disable auto suspend to prevent the momentary Xbox controller connection drops during play.
  boot.kernelParams = [ "btusb.enable_autosuspend=0" ];

  programs.kdeconnect.enable = true;
  services.tailscale.enable = true;

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
    streamcontroller
    vintagestory
    winboat

    stable.pcsx2
    stable.rpcs3
    stable.dolphin-emu
  ];

  system.stateVersion = "26.05";
}
