# Dedicated ext4 disk holding the atticd NAR/chunk store at /mnt/attic.
# `nofail` so a missing/unplugged disk never blocks boot. `noatime` because
# this is a read-heavy blob store — no reason to write access times on reads.
let
  ext4DataMount = uuid: {
    device = "/dev/disk/by-uuid/${uuid}";
    fsType = "ext4";
    options = [
      "defaults"
      "users"
      "nofail"
      "exec"
      "noatime"
    ];
  };
in
{
  fileSystems."/mnt/attic" = ext4DataMount "279be7a7-6370-43b1-93b7-7c44a0e2e76b";
}
