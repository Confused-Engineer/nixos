# Single overlay that adds every custom package in this directory.
#
# To add a new package:
#   1. Drop a `pkgs/<name>/package.nix` file with a callPackage-able derivation.
#   2. Add `<name> = final.callPackage ./<name>/package.nix { };` below.
#
# Then reference it as `pkgs.<name>` from any module — no per-machine
# `nixpkgs.config.packageOverrides` needed.

final: prev: {
  apps2samsung = final.callPackage ./apps2samsung/package.nix { };
  jellyfin2samsung = final.callPackage ./jellyfin2samsung/package.nix { };
  shizuku-linux = final.callPackage ./shizuku-linux/package.nix { };
  system-api = final.callPackage ./system-api/package.nix { };
  vintagestory = final.callPackage ./vintagestory/package.nix { };
}
