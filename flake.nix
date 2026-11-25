{
  description = "Multi-machine NixOS config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    claude-code-nix.url = "github:ryoppippi/nix-claude-code";
    # CachyOS kernel + friends, for desktop's cachyos-kernel specialisation.
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    # Nous Research's Hermes agent. Not pinned to our nixpkgs on purpose:
    # upstream's modules use their own locked, tested build.
    hermes-agent.url = "github:NousResearch/hermes-agent";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Dendritic plumbing: flake-parts evaluates every file under ./modules
    # (collected by import-tree) as one flake-parts module.
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs-unstable";
    };
    import-tree.url = "github:vic/import-tree";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  # CI (nix-installer-action extra-conf) sets `accept-flake-config = true`,
  # which makes these substituters/keys trusted automatically on the
  # gitrunners -- without this, their own ambient nix.conf knows nothing
  # about either cache (the nix.settings.substituters in binary-cache.nix /
  # the chaotic-nyx module only take effect on a host once it switches to
  # that config, not on whatever machine is doing the building), so CI
  # falls back to compiling from source instead of substituting.
  nixConfig = {
    extra-substituters = [
      "https://attic.a5f.org/system"
      "https://nyx-cache.chaotic.cx/"
    ];
    extra-trusted-public-keys = [
      "system:JKldX37z2mGGfjceZeMLKpWdqwE08gE0ddVUwRJ2R3A="
      "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
    ];
  };
}
