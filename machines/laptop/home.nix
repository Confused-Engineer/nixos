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
    ./../../nixosModules/os/ui/hyprland/theme.nix
  ];

  home.username = "david";
  home.homeDirectory = "/home/david";
  home.stateVersion = "25.05";
  #home.sessionVariables.GTK_THEME = "gruvbox-dark";
  programs.bash = {
    enable = true;
    shellAliases = {
      btw = "echo i use hyprland btw";
      nrs = "sudo nixos-rebuild switch --flake /etc/nixos";
      ncs = "sudo nix-collect-garbage; sudo nix-collect-garbage -d; sudo nixos-rebuild switch --flake /etc/nixos";
      vim = "nano";
    };
    initExtra = ''
      export PS1='\[\e[38;5;76m\]\u\[\e[0m\] in \[\e[38;5;32m\]\w\[\e[0m\] \\$ '
      nitch
    '';
    profileExtra = ''
      if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
        exec uwsm start -S hyprland-uwsm.desktop
      fi
    '';
  };

  home.packages = with pkgs; [
    adwaita-icon-theme          # icon theme
             # Adwaita dark theme for GTK 3
    libadwaita         # Adwaita dark theme for GTK 4
  #  ripgrep
  #  nil
  #  nixpkgs-fmt
  #  nodejs
  #  gcc
  #  wofi
    nitch
    rofi
    obsidian
    vscode
    git
    discord
    plexamp
    spotify
    neofetch
    pavucontrol
    moonlight-qt
    jellyfin-media-player
    (pkgs.kodi.withPackages (kodiPkgs: with kodiPkgs; [
		  jellyfin
      inputstream-adaptive
	]))
  ];


  xdg.configFile = builtins.mapAttrs
    (name: subpath: {
      source = create_symlink "${dotfiles}/${subpath}";
      recursive = true;
    })
    configs;

}
