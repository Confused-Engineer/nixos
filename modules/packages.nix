# Custom packages. Every `pkgs/<name>/package.nix` (a callPackage-able
# derivation) becomes `pkgs.<name>` on every host via this overlay, which
# the `nixpkgs` aspect (modules/base/nixpkgs.nix) applies. To add a
# package, just create `pkgs/<name>/package.nix` — no list to update.
{
  flake.overlays.default =
    final: prev:
    prev.lib.packagesFromDirectoryRecursive {
      inherit (final) callPackage;
      directory = ../pkgs;
    };
}
