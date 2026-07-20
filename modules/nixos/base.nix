# nixpkgs configuration + overlays shared by every host. Was the inline module
# inside mkSystem's module list.
#
# `inputs` arrives via specialArgs (set in each modules/hosts/*.nix).
{
  flake.modules.nixos.base =
    { inputs, ... }:
    {
      nixpkgs = {
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [ "electron-40.10.5" ];
        };
        overlays = [
          # Expose the stable channel as `pkgs.stable` (system pkgs may be
          # unstable). Inherits allowUnfree so e.g. `pkgs.stable.pcsx2` works.
          (final: prev: {
            stable = import inputs.nixpkgs {
              inherit (prev.stdenv.hostPlatform) system;
              config.allowUnfree = true;
            };
          })
          # All custom packages, as one overlay (pkgs/default.nix).
          (import ../../pkgs)
        ];
      };
    };
}
