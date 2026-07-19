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
  fileSystems."/media/Games" = ext4DataMount "1c39032b-b81a-410d-9d7f-4a9ae60073d4";
  fileSystems."/media/Extra01" = ext4DataMount "8c36d5a0-4afc-4bea-95be-6da718b570f8";
  fileSystems."/media/Extra02" = ext4DataMount "c3c0b3cb-2f63-47aa-b388-362bac34c7fa";
}
