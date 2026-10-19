# g5-5587 — Dell G5 5587 (2018), i7 + GTX 1060 Optimus laptop.
# Pascal dGPU → closed driver (open = false) with PRIME offload against the
# Intel iGPU. `steam-os.nix` adds a boot-menu specialisation that drops the
# DE and boots straight into Steam Big Picture.
{ inputs, self, ... }:
{
  flake.nixosConfigurations.g5-5587 = inputs.nixpkgs-unstable.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ self.modules.nixos.g5-5587 ];
  };

  flake.modules.nixos.g5-5587 =
    { pkgs, ... }:
    {
      imports = with self.modules.nixos; [
        nixpkgs
        binary-cache
        home-manager

        firefox
        steam
        controller-xbox
        gpu-nvidia
        boot
        de-cosmic
        gc
        settings-common
        settings-baseline
      ];

      custom = {
        firefox = {
          privacy = "strict";
          homepage = "https://hp.a5f.org/";
        };

        gpu-nvidia = {
          open = false; # Pascal (GTX 1060) — open modules unsupported
          prime.enable = true;
          # ponytail: placeholder bus IDs — set from `lspci | grep -E 'VGA|3D'`.
          # G5 5587 is typically intel 00:02.0, nvidia 01:00.0 (the defaults),
          # but confirm on the box before trusting them.
        };

        de-cosmic = {
          strip.enable = true;
          nvidiaFix.hibernate = false;
        };

        boot = {
          fancy.enable = true;
          fancy.secureBoot = false;
          systemd = false;
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
      boot.kernelPackages = pkgs.linuxPackages_zen;

      system.stateVersion = "26.05";
    };
}
