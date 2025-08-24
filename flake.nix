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
            
            (self: super: { unstable = import nixpkgs-unstable { system = "x86_64-linux"; }; }) 

            (final: prev: {
              bambu-studio = prev.bambu-studio.overrideAttrs (oldAttrs: {
                buildInputs = oldAttrs.buildInputs or [ ] ++ [ pkgs.makeWrapper ];
                postInstall = oldAttrs.postInstall or "" + ''
                  wrapProgram $out/bin/bambu-studio \
                    --set __GLX_VENDOR_LIBRARY_NAME mesa \
                    --set __EGL_VENDOR_LIBRARY_FILENAMES "${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json" \
                    --set MESA_LOADER_DRIVER_OVERRIDE zink \
                    --set GALLIUM_DRIVER zink \
                    --set WEBKIT_DISABLE_DMABUF_RENDERER 1
                '';
              });
            })

            (final: prev: {
              orca-slicer = prev.orca-slicer.overrideAttrs (oldAttrs: {
                buildInputs = oldAttrs.buildInputs or [ ] ++ [ pkgs.makeWrapper ];
                postInstall = oldAttrs.postInstall or "" + ''
                  wrapProgram $out/bin/orca-slicer \
                    --set __GLX_VENDOR_LIBRARY_NAME mesa \
                    --set __EGL_VENDOR_LIBRARY_FILENAMES "${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json" \
                    --set MESA_LOADER_DRIVER_OVERRIDE zink \
                    --set GALLIUM_DRIVER zink \
                    --set WEBKIT_DISABLE_DMABUF_RENDERER 1
                '';
              });
            })

          ];};
        })
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