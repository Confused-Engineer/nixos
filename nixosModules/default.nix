
{ config, pkgs, lib, ... }:

{

    imports = [
        ./apps/gaming/steam.nix
        ./services/system_api.nix
        ./services/shizuku_linux.nix
        ./os/autoClean.nix
        ./os/autoUpgrade.nix
        ./os/ui/gnome/gnome.nix
        ./hardware/gpu/nvidia.nix
    ];

}