
{ config, pkgs, lib, ... }:

{

    imports = [
        ./apps/gaming/steam.nix
        ./apps/gaming/steamSystemd.nix
        ./services/system_api.nix
        ./os/autoclean.nix
        ./os/ui/gnome/gnome.nix
        ./os/ui/gnome/strip_defaults.nix
        ./os/ui/gnome/extensions.nix
    ];

}