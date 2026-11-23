# Zen kernel, pinned to whatever's latest in nixpkgs-unstable at any given
# flake.lock revision. A boot-menu specialisation mirroring stable-kernel.nix
# so zen can be re-tested on demand (e.g. after switching the default boot to
# stable-kernel while chasing a regression) without touching the default
# boot entry. Pick the "zen-kernel" entry in the limine menu, or switch live
# with:
#   sudo /run/current-system/specialisation/zen-kernel/bin/switch-to-configuration test
{
  flake.modules.nixos.desktop =
    { pkgs, lib, ... }:
    {
      specialisation.latest-kernel.configuration = {
        system.nixos.tags = [ "latest-kernel" ];
        boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
      };
    };
}
