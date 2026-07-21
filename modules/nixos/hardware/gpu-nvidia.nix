{
  flake.modules.nixos.custom =
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
        enable = lib.mkEnableOption "NVIDIA proprietary driver";

        open = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Use the open kernel modules. Default true (required-ish on Turing+
            RTX cards). Set false for Maxwell/Pascal (GTX 9xx/10xx), which the
            open modules don't support.
          '';
        };

        prime = {
          enable = lib.mkEnableOption "PRIME render offload (Optimus laptops)";
          # ponytail: placeholders — read real values with `lspci | grep -E 'VGA|3D'`
          # then convert e.g. 00:02.0 -> "PCI:0:2:0", 01:00.0 -> "PCI:1:0:0".
          intelBusId = lib.mkOption {
            type = lib.types.str;
            default = "PCI:0:2:0";
            description = "Bus ID of the Intel iGPU (PLACEHOLDER — set per host).";
          };
          nvidiaBusId = lib.mkOption {
            type = lib.types.str;
            default = "PCI:1:0:0";
            description = "Bus ID of the NVIDIA dGPU (PLACEHOLDER — set per host).";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        hardware.graphics.enable = true;
        services.xserver.videoDrivers = [ "nvidia" ];

        hardware.nvidia = {
          modesetting.enable = true;
          powerManagement.enable = true;
          # Fine-grained PM powers the dGPU down when idle — wanted on offload
          # laptops, off on the always-on desktop.
          powerManagement.finegrained = cfg.prime.enable;
          open = cfg.open;
          nvidiaSettings = true;
          package = config.boot.kernelPackages.nvidiaPackages.latest;

          prime = lib.mkIf cfg.prime.enable {
            offload.enable = true;
            offload.enableOffloadCmd = true; # provides `nvidia-offload` wrapper
            intelBusId = cfg.prime.intelBusId;
            nvidiaBusId = cfg.prime.nvidiaBusId;
          };
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
    };
}
