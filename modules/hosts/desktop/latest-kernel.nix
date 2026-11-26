# CachyOS kernel for desktop, pulled from Chaotic-Nyx (chaotic-cx/nyx) rather
# than nixpkgs, which doesn't package it. A boot-menu specialisation, not the
# default -- try it from the limine menu first, see docker.nix/steam-os.nix
# for the general pattern. The chaotic-nyx module is imported in
# configuration.nix only for this host (provides pkgs.linuxPackages_cachyos
# and its overlay). Pick the "latest-kernel" entry in the limine menu, or
# switch live with:
#   sudo /run/current-system/specialisation/latest-kernel/bin/switch-to-configuration test
#
# Note: Chaotic-Nyx also ships linuxPackages_cachyos-lto, but doesn't
# maintain its kernel modules (see their README) -- stick to the plain
# cachyos variant for anything that needs out-of-tree modules (openrazer,
# nvidia, etc.), which this host uses.
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
