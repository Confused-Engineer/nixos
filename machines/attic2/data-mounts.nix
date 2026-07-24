# Shared ext4 data disks for the desktop, used by both the default config and
# the SteamOS specialisation. `nofail` so a missing/unplugged disk never blocks
# boot.
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
  fileSystems."/mnt/attic" = ext4DataMount "279be7a7-6370-43b1-93b7-7c44a0e2e76b";
}
