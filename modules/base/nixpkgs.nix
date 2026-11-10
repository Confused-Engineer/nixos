# nixpkgs settings every host imports: unfree, the custom-package overlay
# (modules/packages.nix), and `pkgs.stable`.
{ inputs, self, ... }:
{
  flake.modules.nixos.nixpkgs = {
    nixpkgs = {
      config = {
        allowUnfree = true;
        permittedInsecurePackages = [ "electron-40.10.5" ];
      };
      overlays = [
        # Exposes the stable channel as `pkgs.stable` (the unstable-based
        # hosts use it to reach across channels, e.g. `pkgs.stable.pcsx2`).
        # Inherits allowUnfree so that works without surprises.
        (final: prev: {
          stable = import inputs.nixpkgs {
            inherit (prev.stdenv.hostPlatform) system;
            config.allowUnfree = true;
          };
        })
        self.overlays.default
      ];
    };
  };
}
