{ lib, pkgs, config, ... }:
let
  cfg = config.custom.hardware.controllers;
in {
  options.custom.hardware.controllers = {
    xbox.enable = lib.mkEnableOption "Xbox controller (xpadneo + bluetooth tweaks for pairing)";
  };

  config = lib.mkIf cfg.xbox.enable {
    hardware.bluetooth = {
      enable      = true;
      powerOnBoot = true;
      # Tweaks recommended for Xbox Series controller pairing reliability —
      # see https://www.reddit.com/r/NixOS/comments/1ch5d2p/comment/lkbabax/
      settings.General = {
        experimental       = false;
        Privacy            = "device";
        JustWorksRepairing = "always";
        Class              = "0x000100";
        FastConnectable    = true;
      };
    };

    services.blueman.enable = true;
    hardware.xpadneo.enable = true;
  };
}
