{ config, lib, pkgs, ... }:
let
  ext4DataMount = uuid: {
    device  = "/dev/disk/by-uuid/${uuid}";
    fsType  = "ext4";
    options = [ "defaults" "users" "nofail" "exec" ];
  };
in {
  imports = [
    ./hardware-configuration.nix
    ./../../nixosModules
    ./../baseline.nix
    ./steam-os.nix
  ];

  custom = {
    apps = {
      steam.enable          = true;
      steam.systemd.enable  = false;

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
        enable          = true;
        disableAccounts = false;
        privacy         = "strict";
        homepage        = "https://hp.int.a5f.org/";
      };
    };

    hardware.gpu.nvidia.enable      = true;
    hardware.gpu.lact.enable        = true;
    hardware.controllers.xbox.enable = true;

    boot = {
      enable             = true;
      fancy.enable       = true;
      fancy.secureBoot   = true;
      systemd            = false;
    };

    os.ui.cosmic = {
      enable              = true;
      strip.enable        = true;
      nvidiaFix.hibernate = true;
    };

    systemd = {
      system-api.enable    = true;
      shizuku-linux.enable = false;
    };
  };

  networking.hostName = "desktop";

  boot.kernelModules  = [ "ntsync" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  programs.kdeconnect.enable = true;
  hardware.openrazer.enable  = true;

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

  fileSystems."/media/Games"   = ext4DataMount "1c39032b-b81a-410d-9d7f-4a9ae60073d4";
  fileSystems."/media/Extra01" = ext4DataMount "8c36d5a0-4afc-4bea-95be-6da718b570f8";
  fileSystems."/media/Extra02" = ext4DataMount "c3c0b3cb-2f63-47aa-b388-362bac34c7fa";

  system.stateVersion = "25.11";
}
