{
  description = "Multi-machine NixOS config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, nixos-hardware, home-manager, ... }:
    let
      lib = nixpkgs-unstable.lib;

      mkSystem =
        { hostname
        , system ? "x86_64-linux"
        , stateNixpkgs ? nixpkgs-unstable
        , useHomeManager ? true
        , hardwareModules ? [ ]
        }:
        stateNixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            {
              nixpkgs.overlays = [
                (final: prev: {
                  stable = import nixpkgs {
                    inherit system;
                    config.permittedInsecurePackages = [ "mbedtls-2.28.10" ];
                    config.allowUnfree = true;
                  };
                  unstable = import nixpkgs-unstable {
                    inherit system;
                    config.allowUnfree = true;
                  };
                })
                (final: prev: {
                  jellyfin2samsung = final.callPackage ./nixosModules/apps/custom/Jellyfin2Samsung/package.nix { };
                  shizuku-linux = final.callPackage ./nixosModules/apps/custom/shizuku-linux/package.nix { };
                  system-api = final.callPackage ./nixosModules/apps/custom/system-api/package.nix { };
                  vintagestory = final.callPackage ./nixosModules/apps/custom/vintagestory/package.nix { };
                })
              ];
            }
            ./machines/${hostname}/configuration.nix
          ] ++ hardwareModules
            ++ lib.optionals useHomeManager [
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.david = import ./homeManager/david.nix;
                backupFileExtension = "backup";
              };
            }
          ];
        };
    in {
      nixosConfigurations = {
        desktop  = mkSystem { hostname = "desktop"; };
        laptop   = mkSystem { hostname = "laptop"; hardwareModules = [ nixos-hardware.nixosModules.dell-latitude-5520 ]; };
        kodi     = mkSystem { hostname = "kodi"; stateNixpkgs = nixpkgs; useHomeManager = false; };
      };
    };
}