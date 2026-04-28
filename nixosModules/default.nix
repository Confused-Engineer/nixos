{ config, pkgs, lib, ... }:

{
  imports = [
    ./apps/browsers/firefox
    ./apps/flatpak
    ./apps/gaming/steam
    ./boot
    ./hardware/controllers
    ./hardware/gpu/lact
    ./hardware/gpu/nvidia
    ./os/ui/cosmic
    ./os/ui/gnome
    ./os/ui/kde
    ./os/ui/kodi
    ./systemd/shizuku-linux
    ./systemd/system-api
  ];
}
