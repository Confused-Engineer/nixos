{ config, pkgs, ... }:
let
  dotfiles = "/etc/nixos/machines/laptop/dotfiles/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
  configs = {
    hypr = "hypr";
    nvim = "nvim";
    wofi = "wofi";
    rofi = "rofi";
    foot = "foot";
    waybar = "waybar";
    nwg-look = "nwg-look";
    nwg-dock-hyprland = "nwg-dock-hyprland";
    wlogout = "wlogout";
    wallpaper = "wallpaper";
    kitty = "kitty";
  };
in
{

  imports = [
    ./../../nixosModules/home-manager
  ];

  custom = {
    shell.bash = {
      enable = true;
      fancy = true;
      nixosAlias = true;
      startHyprland = false;
    };
  };

  home.username = "david";
  home.homeDirectory = "/home/david";
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    brave
    moonlight-qt
    obsidian
    spotify
    vlc
    vscode
    discord
    libreoffice
    (pkgs.kodi.withPackages (
      kodiPkgs: with kodiPkgs; [
        jellyfin
        inputstream-adaptive
      ]
    ))
  ];

  #xdg.configFile = builtins.mapAttrs (name: subpath: {
  #  source = create_symlink "${dotfiles}/${subpath}";
  #  recursive = true;
  #}) configs;

}
