{
  description = "Flakes basic Template";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, ... }: {

    nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          nixpkgs = { overlays = [
            
            (self: super: { unstable = import nixpkgs-unstable { system = "x86_64-linux"; config.allowUnfree = true; }; }) 

          ];};
        })

        ({ pkgs, config, lib, ... }: 
          let
            zfsCompatibleKernelPackages = lib.filterAttrs (
              name: kernelPackages:
              (builtins.match "linux_[0-9]+_[0-9]+" name) != null
              && (builtins.tryEval kernelPackages).success
              && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken)
            ) pkgs.linuxKernel.packages;
            latestKernelPackage = lib.last (
              lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (
                builtins.attrValues zfsCompatibleKernelPackages
              )
            );
          in
          {
            # Note this might jump back and forth as kernels are added or removed.
            boot.kernelPackages = latestKernelPackage;
          }
        )
        ./machines/desktop/configuration.nix
      ];
    };

    nixosConfigurations.vacation = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          nixpkgs = { overlays = [
            
            (self: super: { unstable = import nixpkgs-unstable { system = "x86_64-linux"; }; }) 


          ];};
        })
        ./machines/vacation/configuration.nix
      ];
    };

    nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          nixpkgs = { overlays = [(self: super: { unstable = import nixpkgs-unstable { system = "x86_64-linux"; }; }) ]; };
        })
        ./machines/laptop/configuration.nix
      ];
    };

    nixosConfigurations.lat9430 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          nixpkgs = { overlays = [(self: super: { unstable = import nixpkgs-unstable { system = "x86_64-linux"; }; }) ]; };
        })
        ./machines/lat9430/configuration.nix
      ];
    };

    nixosConfigurations.kodi = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          nixpkgs = { overlays = [(self: super: { unstable = import nixpkgs-unstable { system = "x86_64-linux"; }; }) ]; };
        })
        ./machines/kodi/configuration.nix
      ];
    };

  };
}