{ lib, pkgs, config, ... }:
let
  cfg = config.custom.hardware.gpu.nvidia;
in {
  options.custom.hardware.gpu.nvidia = {
    enable = lib.mkEnableOption "NVIDIA proprietary driver (open kernel modules)";
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics.enable    = true;
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      modesetting.enable             = true;
      powerManagement.enable         = true;
      powerManagement.finegrained    = false;
      open                           = true;
      nvidiaSettings                 = true;
      package                        = config.boot.kernelPackages.nvidiaPackages.beta;
    };
  };
}
