# Aggregator. Each helper lives in its own subdir as `lib/<name>/default.nix`
# so it can grow companion files (tests, README, sub-helpers) without forcing
# a directory split later. Callers can either:
#
#   helpers = import ./lib { inherit lib pkgs; };
#   helpers.mkNvidiaSuspendFix { name = "cosmic"; binary = "..."; }
#
# or reach in directly when they only need one:
#
#   mkNvidiaSuspendFix = import ./lib/mkNvidiaSuspendFix { inherit lib pkgs; };

{ lib, pkgs }:

{
  mkNvidiaSuspendFix = import ./mkNvidiaSuspendFix { inherit lib pkgs; };
}
