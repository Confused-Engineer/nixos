# Xbox controller support: xpadneo + bluetooth tweaks for pairing.
{
  flake.modules.nixos.controller-xbox = {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      # Tweaks recommended for Xbox Series controller pairing reliability —
      # see https://www.reddit.com/r/NixOS/comments/1ch5d2p/comment/lkbabax/
      settings.General = {
        experimental = false;
        Privacy = "device";
        JustWorksRepairing = "always";
        Class = "0x000100";
        FastConnectable = true;
      };
    };

    services.blueman.enable = true;
    hardware.xpadneo.enable = true;
  };
}
