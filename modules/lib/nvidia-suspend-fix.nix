# `self.lib.mkNvidiaSuspendFix pkgs { name, binary }`
#
# Build a pair of systemd services that pause/resume a long-lived shell
# process across suspend/hibernate. Works around the well-known NVIDIA
# bug where Wayland compositors hang on resume because of stale GBM
# buffers — the fix is to STOP the compositor before suspend and CONT
# it after resume.
#
# Usage, inside a NixOS module:
#   systemd = self.lib.mkNvidiaSuspendFix pkgs {
#     name   = "cosmic";
#     binary = "${pkgs.cosmic-osd}/bin/cosmic-osd";
#   };
#
# Returns an attrset suitable for `systemd = ...;` containing the two
# services. Compose with lib.mkMerge if you have other systemd config.
{
  flake.lib.mkNvidiaSuspendFix =
    pkgs:
    { name, binary }:
    {
      services."${name}-suspend" = {
        description = "Pause ${name} before suspend/hibernate (NVIDIA fix)";
        before = [
          "systemd-suspend.service"
          "systemd-hibernate.service"
          "nvidia-suspend.service"
          "nvidia-hibernate.service"
        ];
        wantedBy = [
          "systemd-suspend.service"
          "systemd-hibernate.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.procps}/bin/pkill -f -STOP ${binary}";
        };
      };

      services."${name}-resume" = {
        description = "Resume ${name} after suspend/hibernate (NVIDIA fix)";
        after = [
          "systemd-suspend.service"
          "systemd-hibernate.service"
          "nvidia-resume.service"
        ];
        wantedBy = [
          "systemd-suspend.service"
          "systemd-hibernate.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.procps}/bin/pkill -f -CONT ${binary}";
        };
      };
    };
}
