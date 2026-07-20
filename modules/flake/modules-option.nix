# Dendritic core: the `flake.modules.<class>.<name>` registry.
#
# Every feature file writes its module into `flake.modules.nixos.<name>` or
# `flake.modules.homeManager.<name>`. Because the leaf type is `deferredModule`,
# many files may target the SAME name and they merge into one module — that's
# how we aggregate all `custom.*` option-modules under a single `custom` name
# that every host imports, reproducing the old `imports = [ ./nixosModules ]`.
#
# Hosts (modules/hosts/*.nix) then read `config.flake.modules.nixos.<name>`
# and hand the chosen modules to `nixosSystem`.
{ lib, ... }:
{
  options.flake.modules = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.deferredModule);
    default = { };
    description = "Named NixOS / home-manager modules, aggregated dendritically.";
  };

  # Also declare the flake output we assemble by hand, so `systems`/`perSystem`
  # stay unused and flake-parts doesn't demand a system list.
  config.systems = [ "x86_64-linux" ];
}
