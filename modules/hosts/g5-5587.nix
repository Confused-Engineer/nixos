# g5-5587 — Dell G5 5587 (2018), i7 + GTX 1060 Optimus laptop.
# Unstable nixpkgs, home-manager, steam. Pascal dGPU → closed driver
# (open = false) with PRIME offload against the Intel iGPU.
{ config, inputs, ... }:
let
  nixos = config.flake.modules.nixos;
in
{
  flake.nixosConfigurations.g5-5587 = inputs.nixpkgs-unstable.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      nixos.base
      nixos.common
      nixos.baseline
      nixos.custom
      nixos.binaryCache
      nixos.cudaCache
      nixos.homeManager

      ../../machines/g5-5587/hardware-configuration.nix

      (
        { pkgs, ... }:
        {
          custom = {
            apps = {
              steam.enable = true;

              browsers.firefox = {
                enable = true;
                privacy = "strict";
                homepage = "https://hp.int.a5f.org/";
              };
            };

            hardware.gpu.nvidia = {
              enable = true;
              open = false; # Pascal (GTX 1060) — open modules unsupported
              prime.enable = true;
              # ponytail: placeholder bus IDs — set from `lspci | grep -E 'VGA|3D'`.
              # G5 5587 is typically intel 00:02.0, nvidia 01:00.0 (the defaults),
              # but confirm on the box before trusting them.
            };

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
              system-api.enable = false;
              shizuku-linux.enable = false;
            };
          };

          networking.hostName = "g5-5587";

          services.power-profiles-daemon.enable = true;
          powerManagement.enable = true;
          services.thermald.enable = true;

          hardware.graphics.extraPackages = with pkgs; [
            intel-vaapi-driver
            intel-media-driver
          ];
          boot.kernelPackages = pkgs.linuxPackages_latest;

          system.stateVersion = "25.11";
        }
      )
    ];
  };
}
