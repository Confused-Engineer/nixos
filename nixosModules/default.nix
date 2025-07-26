
{ config, pkgs, lib, ... }:

{

    imports = [
        ./apps/gaming/steam.nix
        ./apps/flatpak.nix
        ./apps/browsers/firefox.nix
        ./systemd/system_api.nix
        ./systemd/shizuku_linux.nix
        ./os/autoClean.nix
        ./os/autoUpgrade.nix
        ./os/ui/gnome/gnome.nix
        ./os/ui/cosmic/cosmic.nix
        ./hardware/gpu/nvidia.nix
        ./hardware/controllers/xbox.nix
    ];

}