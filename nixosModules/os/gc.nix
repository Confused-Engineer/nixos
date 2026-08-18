# Boot-loader-agnostic generation pruning + garbage collection.
#
# `nix.gc` on its own only sweeps store paths that are already unreferenced
# by a live profile generation — it never deletes generations themselves.
# systemd-boot's `configurationLimit` happens to unlink old generation
# profile links itself once past the limit, which is what makes plain
# `nix.gc` look sufficient there. Limine's `maxGenerations` does not: it
# only trims what shows in the boot menu, so the underlying profile links
# (and everything they keep alive) accumulate forever. This module prunes
# the system profile directly instead of leaning on either loader, so
# behavior is identical regardless of which one a host uses.
{
  lib,
  config,
  ...
}:
let
  cfg = config.custom.os.gc;
in
{
  options.custom.os.gc = {
    enable = lib.mkEnableOption "automatic nix generation pruning and garbage collection";

    generations = lib.mkOption {
      type = lib.types.ints.positive;
      default = 3;
      description = "Number of most-recent system generations to keep. Older ones are deleted before the store is swept.";
    };

    dates = lib.mkOption {
      type = lib.types.str;
      default = "weekly";
      description = "systemd calendar spec for how often generations are pruned and garbage is collected.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Bound the boot menu itself too. Setting the option for whichever
    # loader isn't in use is inert.
    boot.loader.systemd-boot.configurationLimit = cfg.generations;
    boot.loader.limine.maxGenerations = cfg.generations;

    nix.gc = {
      automatic = true;
      inherit (cfg) dates;
    };

    systemd.services.nix-gc.serviceConfig.ExecStartPre = [
      "${config.nix.package}/bin/nix-env -p /nix/var/nix/profiles/system --delete-generations +${toString cfg.generations}"
    ];
  };
}
