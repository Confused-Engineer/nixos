let
  mkSystem = { hostname, system ? "x86_64-linux", stateNixpkgs ? nixpkgs-unstable, useHomeManager ? true }:
    stateNixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        { nixpkgs.overlays = [ (final: prev: {
            stable = import nixpkgs { inherit system; config.allowUnfree = true; };
            unstable = import nixpkgs-unstable { inherit system; config.allowUnfree = true; };
          }) ]; }
        ./machines/${hostname}/configuration.nix
      ] ++ lib.optionals useHomeManager [
        home-manager.nixosModules.home-manager
        { home-manager = {
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
    desktop = mkSystem { hostname = "desktop"; };
    laptop = mkSystem { hostname = "laptop"; };
    lat9430 = mkSystem { hostname = "lat9430"; stateNixpkgs = nixpkgs; };
    vacation = mkSystem { hostname = "vacation"; stateNixpkgs = nixpkgs; useHomeManager = false; };
    kodi = mkSystem { hostname = "kodi"; stateNixpkgs = nixpkgs; useHomeManager = false; };
  };
}