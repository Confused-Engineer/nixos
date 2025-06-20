
{ config, pkgs, lib, ... }:

{

    imports = [
        ./apps/gaming/steam.nix
        ./services/system_api.nix
        ./os/autoclean.nix
        ./os/ui/gnome/gnome.nix
        ./hardware/gpu/nvidia.nix
    ];

}