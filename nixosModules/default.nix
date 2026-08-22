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
    ./apps/lact.nix
    ./apps/steam.nix
    ./hardware/controller-xbox.nix
    ./hardware/gpu-nvidia.nix
    ./os/boot.nix
    ./os/de-cosmic.nix
    ./os/de-gnome.nix
    ./os/de-kde.nix
    ./os/de-kodi.nix
    ./os/gc.nix
    ./os/settings-common.nix
    ./os/settings-baseline.nix
    ./systemd/shizuku-linux.nix
    ./systemd/system-api.nix
    ./virtualization/blocky.nix
    ./virtualization/container-host.nix
    # virtualization/proxmox-vm.nix is deliberately not imported here — see
    # that file's header comment.
  ];
}
