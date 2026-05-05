# When evaluating the *root* host config (no specialisation active),
# `config.specialisation` contains the set of declared specialisations
# (it is non-empty). When evaluating *inside* a specialisation, the
# spec's own `config.specialisation` is `{}`. We exploit that to
# enable Kodi only on the default boot, and leave the `desktop`
# specialisation as a plain cosmic session for maintenance.
#
# This file used to be called `default-only.nix`, which gave no hint
# about what the conditional was doing.

{ config, lib, pkgs, ... }:
{
  config = lib.mkIf (config.specialisation != {}) {
    custom.os.ui.kodi.enable = true;
  };
}
