
{ config, pkgs, lib, ... }:

{

    imports = [
        ./apps/browsers/firefox.nix
        ./apps/flatpak.nix
        ./apps/gaming/steam.nix
        ./boot
        ./hardware/controllers/xbox.nix
        ./hardware/gpu/lact.nix
        ./hardware/gpu/nvidia.nix
        ./os/ui/cosmic/cosmic.nix
        ./os/ui/gnome/gnome.nix
        ./os/ui/kde/plasma6.nix
        ./os/ui/kodi/kodi.nix
        ./systemd/shizuku_linux.nix
        ./systemd/system_api.nix
    ];

}