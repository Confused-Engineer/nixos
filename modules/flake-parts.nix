# Flake-level plumbing. Every .nix file under ./modules is a flake-parts
# module (collected by import-tree in flake.nix); this one switches on the
# pieces the rest of the tree relies on.
{
  inputs,
  lib,
  flake-parts-lib,
  ...
}:
{
  imports = [
    # Provides `flake.modules.<class>.<name>`, the registry every feature
    # ("aspect") file contributes to and every host imports from.
    inputs.flake-parts.flakeModules.modules
  ];

  # `flake.lib.<name>`: plain helper functions shared between modules.
  # Declared here so several files can each add a helper; flake-parts'
  # default freeform `flake.*` attrs only accept a single definition.
  options.flake = flake-parts-lib.mkSubmoduleOptions {
    lib = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
      description = "Helper functions shared between modules, reachable as `self.lib.<name>`.";
    };
  };

  # Required by flake-parts. Every host is x86_64-linux.
  config.systems = [ "x86_64-linux" ];
}
