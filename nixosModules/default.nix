{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./apps/firefox.nix
    ./apps/flatpak.nix
    ./apps/steam.nix
    ./apps/lact.nix
    ./os/boot.nix
    ./hardware/controllers-xbox.nix
    ./hardware/gpu-nvidia.nix
    ./os/de-cosmix.nix
    ./os/de-gnome.nix
    ./os/de-kde.nix
    ./os/de-kodi.nix
    ./os/settings-common.nix
    ./os/settings-baseline.nix
    ./systemd/shizuku-linux.nix
    ./systemd/system-api.nix
  ];
}
