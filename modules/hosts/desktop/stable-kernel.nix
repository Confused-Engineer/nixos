# Fallback kernel for desktop. A boot-menu specialisation that inherits the
# whole host config but swaps linuxPackages_zen for the mainline stable
# kernel, in case a zen-specific regression (NVIDIA driver ABI mismatch,
# a zen patch bug, etc.) makes the default boot unusable. Default boot stays
# on the zen kernel; pick the "stable-kernel" entry in the limine menu, or
# switch live with:
#   sudo /run/current-system/specialisation/stable-kernel/bin/switch-to-configuration test
{
  flake.modules.nixos.desktop =
    { pkgs, lib, ... }:
    {
      specialisation.stable-kernel.configuration = {
        system.nixos.tags = [ "stable-kernel" ];
        boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
      };
    };
}
