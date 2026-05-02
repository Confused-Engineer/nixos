{ lib, pkgs, config, ... }:                    
let
  cfg = config.custom.hardware.gpu;
in {
  options.custom.hardware.gpu = {
    nvidia.enable = lib.mkEnableOption "Use nvidia GPU";
  };
  config = lib.mkIf cfg.nvidia.enable {

    hardware.graphics.enable = true;
    services.xserver.videoDrivers = ["nvidia"];
    hardware.nvidia = {
      # Modesetting is required.
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.beta;
     # package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
     #   version = "580.95.05";
     #   sha256_64bit = "sha256-hJ7w746EK5gGss3p8RwTA9VPGpp2lGfk5dlhsv4Rgqc=";
     #   sha256_aarch64 = "sha256-Puz4MtouFeDgmsNMKdLHoDgDGC+QRXh6NVysvltWlbc=";
     #   openSha256 = "sha256-ZpuVZybW6CFN/gz9rx+UJvQ715FZnAOYfHn5jt5Z2C8=";
     #   settingsSha256 = "sha256-ZpuVZybW6CFN/gz9rx+UJvQ715FZnAOYfHn5jt5Z2C8=";
     #   persistencedSha256 = lib.fakeSha256;
     # };

    };

  };
}