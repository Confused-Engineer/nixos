{
  description = "Multi-machine NixOS config";

  inputs = {
    nixpkgs.url          = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url   = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url                    = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, nixos-hardware, home-manager, ... }:
    let
      lib = nixpkgs-unstable.lib;

      # Overlay that exposes the *other* channels as `pkgs.stable` / `pkgs.unstable`.
      # Both inherit allowUnfree so reaching across channels (e.g. `pkgs.stable.pcsx2`)
      # works without surprises.
      channelsOverlay = system: final: prev: {
        stable = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            permittedInsecurePackages = [ "mbedtls-2.28.10" ];
          };
        };
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };

      # All custom packages live in ./pkgs and expose themselves as one overlay.
      customPkgs = import ./pkgs;

      mkSystem =
        { hostname
        , system          ? "x86_64-linux"
        # Which nixpkgs evaluates the system. Default unstable; kodi pins stable.
        , stateNixpkgs    ? nixpkgs-unstable
        , useHomeManager  ? true
        , homeUser        ? "david"
        , hardwareModules ? [ ]
        }:
        stateNixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            {
              nixpkgs = {
                config.allowUnfree = true;
                overlays = [
                  (channelsOverlay system)
                  customPkgs
                ];
              };
            }
            ./machines/${hostname}/configuration.nix
          ]
          ++ hardwareModules
          ++ lib.optionals useHomeManager [
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs       = true;
                useUserPackages     = true;
                backupFileExtension = "backup";
                users.${homeUser}   = import (./homeManager + "/${homeUser}.nix");
                # Per-host extensions live in machines/<host>/home.nix and are
                # imported by the user's home file when present.
                extraSpecialArgs    = { inherit inputs hostname; };
              };
            }
          ];
        };
    in {
      nixosConfigurations = {
        desktop = mkSystem { hostname = "desktop"; };
        laptop  = mkSystem {
          hostname        = "laptop";
          hardwareModules = [ nixos-hardware.nixosModules.dell-latitude-5520 ];
        };
        kodi    = mkSystem {
          hostname       = "kodi";
          stateNixpkgs   = nixpkgs;
          useHomeManager = false;
        };
      };
    };
}
