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
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-unstable,
      nixos-hardware,
      home-manager,
      ...
    }:
    let
      lib = nixpkgs-unstable.lib;
      binaryCache = {
        url = "https://attic.a5f.org/system";
        publicKey = "system:OYIcW3XGdarzUi63x+H5mJ4FIhiYZcdiNUdyL7mKKEE=";
      };
      cudaCache = {
        url = "https://cuda-maintainers.cachix.org";
        publicKey = "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E=";
      };

      # Overlay that exposes the stable channel as `pkgs.stable` (the system
      # pkgs is already unstable). Inherits allowUnfree so reaching across
      # channels (e.g. `pkgs.stable.pcsx2`) works without surprises.
      channelsOverlay = system: final: prev: {
        stable = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      };

      # All custom packages live in ./pkgs and expose themselves as one overlay.
      customPkgs = import ./pkgs;

      mkSystem =
        {
          hostname,
          system ? "x86_64-linux",
          # Which nixpkgs evaluates the system. Default unstable; kodi pins stable.
          stateNixpkgs ? nixpkgs-unstable,
          useHomeManager ? true,
          useBinaryCache ? true,
          useCudaCache ? true,
          homeUser ? "david",
          hardwareModules ? [ ],
        }:
        stateNixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            {
              nixpkgs = {
                config = {
                  allowUnfree = true;
                  permittedInsecurePackages = [ "electron-40.10.5" ];
                };
                overlays = [
                  (channelsOverlay system)
                  customPkgs
                ];
              };
            }
            ./machines/${hostname}/configuration.nix
          ]
          ++ lib.optional useBinaryCache {
            nix.settings = {
              substituters = [ binaryCache.url ];
              trusted-public-keys = [ binaryCache.publicKey ];
            };
          }
          ++ lib.optional useCudaCache {
            nix.settings = {
              substituters = [ cudaCache.url ];
              trusted-public-keys = [ cudaCache.publicKey ];
            };
          }
          ++ hardwareModules
          ++ lib.optionals useHomeManager [
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                users.${homeUser} = import (./homeManager + "/${homeUser}.nix");
                # Per-host extensions live in machines/<host>/home.nix and are
                # imported by the user's home file when present.
                extraSpecialArgs = { inherit inputs hostname; };
              };
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        desktop = mkSystem { hostname = "desktop"; };
        laptop = mkSystem {
          hostname = "laptop";
          hardwareModules = [ nixos-hardware.nixosModules.dell-latitude-5520 ];
        };
        g5-5587 = mkSystem { hostname = "g5-5587"; };
        kodi = mkSystem {
          hostname = "kodi";
          stateNixpkgs = nixpkgs;
          useHomeManager = false;
        };
        attic = mkSystem {
          hostname = "attic";
          stateNixpkgs = nixpkgs;
          useHomeManager = false;
          useBinaryCache = false;
        };
      };
    };
}
