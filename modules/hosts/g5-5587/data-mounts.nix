# Shared ext4 data disks for g5-5587, used by both the default config and
# the SteamOS specialisation. `nofail` so a missing/unplugged disk never blocks
# boot.
{
  flake.modules.nixos.g5-5587 =
    let
      ext4DataMount = uuid: {
        device = "/dev/disk/by-uuid/${uuid}";
        fsType = "ext4";
        options = [
          "defaults"
          "users"
          "nofail"
          "exec"
        ];
      };
    in
    {
      fileSystems."/media/Data" = ext4DataMount "8fdd7324-08d5-4524-a578-2c0a1b0b6772";
    };
}
