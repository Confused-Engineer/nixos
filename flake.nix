{
  description = "Multi-machine NixOS config (dendritic)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    claude-code-nix.url = "github:ryoppippi/nix-claude-code";

    # Dendritic pattern scaffolding.
    flake-parts.url = "github:hercules-ci/flake-parts";
    # import-tree turns every *.nix under ./modules into a flake-parts module,
    # so adding a feature is just dropping a file — no central import list.
    import-tree.url = "github:vic/import-tree";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
