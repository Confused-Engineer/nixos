
{ config, pkgs, lib, ... }:

{

    imports = [
        ./apps/gaming/steam.nix
        ./apps/flatpak.nix
        ./hardware/gpu/lact.nix
        ./apps/browsers/firefox.nix
        ./systemd/system_api.nix
        ./systemd/shizuku_linux.nix
        ./os/ui/gnome/gnome.nix
        ./os/ui/cosmic/cosmic.nix
        ./os/ui/kodi/kodi.nix
        ./os/ui/kde/plasma6.nix
        ./hardware/gpu/nvidia.nix
        ./hardware/controllers/xbox.nix
        ./boot
    ];

}