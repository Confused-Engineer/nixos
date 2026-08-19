# Declarative partition table for the Proxmox VM disk. Consumed both by
# `disko` at install time (partitions + formats + mounts /dev/sda) and by
# the built system (contributes the matching `fileSystems.*` entries), so
# there is no hand-written hardware-configuration.nix fstab to keep in sync.
{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
