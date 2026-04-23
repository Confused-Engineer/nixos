{ config, pkgs, ... }:
{
  imports = [
    ./../nixosModules/home-manager
  ];

  custom = {
    shell.bash = {
      enable = true;
      fancy = true;
      nixosAlias = true;
      startHyprland = false;
    };
    mangohud.enable = true;
  };

  home.username = "david";
  home.homeDirectory = "/home/david";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    brave
    gimp
    obsidian
    prismlauncher
    spotify
    vlc
    vscode
    moonlight-qt
    discord
    libreoffice
    (pkgs.kodi.withPackages (
      kodiPkgs: with kodiPkgs; [
        jellyfin
        inputstream-adaptive
      ]
    ))
  ];

  # In your configuration.nix or home-manager config
  home.file.".local/share/flatpak/overrides/com.core447.StreamController".text = ''
    [Context]
    filesystems=/run/user/1000;
  '';

  home.file.".config/autostart/StreamController.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=StreamController
    Exec=flatpak run com.core447.StreamController -b
  '';

  home.file.".local/share/Steam/steam_dev.cfg".text = ''
    unShaderBackgroundProcessingThreads 16
  '';

}
