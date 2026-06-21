{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.custom.hardware.gpu.nvidia;
in
{
  options.custom.hardware.gpu.nvidia = {
    enable = lib.mkEnableOption "NVIDIA proprietary driver (open kernel modules)";
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics.enable = true;
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = false;
      open = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.latest;
    };

    # Load NVIDIA modules in the initrd so the DRM device is fully registered
    # before greetd starts. Without this, cosmic-comp races against nvidia-drm
    # loading, fails to open /dev/dri/card0 (simpledrm, which gets evicted), and
    # greetd hits its restart limit before /dev/dri/card1 (nvidia-drm) appears.
    boot.initrd.kernelModules = [
      "nvidia"
      "nvidia_modeset"
      "nvidia_uvm"
      "nvidia_drm"
    ];
  };
}
