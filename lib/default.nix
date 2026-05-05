# Shared helpers used across modules. Imported via `import ./lib { inherit lib pkgs; }`.

{ lib, pkgs }:

rec {
  # Build a pair of systemd services that pause/resume a long-lived shell
  # process across suspend/hibernate. Works around the well-known NVIDIA
  # bug where Wayland compositors hang on resume because of stale GBM
  # buffers — the fix is to STOP the compositor before suspend and CONT
  # it after resume.
  #
  # Usage:
  #   imports = [ ./suspend-helpers.nix ];     # not needed if used inline
  #   systemd = mkNvidiaSuspendFix {
  #     name    = "cosmic";                    # service prefix
  #     binary  = "${pkgs.cosmic-osd}/bin/cosmic-osd";
  #   };
  #
  # Returns an attrset suitable for `systemd = ...;` containing the two
  # services. Compose with lib.recursiveUpdate or lib.mkMerge if you have
  # other systemd config to add.
  mkNvidiaSuspendFix = { name, binary }: {
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
