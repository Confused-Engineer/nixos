{ config, pkgs, ... }:
let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;

  configs = {
    hypr = "hypr";
    nvim = "nvim";
    wofi = "wofi";
    rofi = "rofi";
    foot = "foot";
    waybar = "waybar";
  };
in
{
  imports = [
    ./../../nixosModules/os/ui/hyprland/theme.nix
  ];

  home.username = "david";
  home.homeDirectory = "/home/david";
  home.stateVersion = "25.05";
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
    neovim
    ripgrep
    nil
    nixpkgs-fmt
    nodejs
    gcc
    wofi
    nitch
    rofi
    pcmanfm
    kdePackages.dolphin
    plexamp
    discord
    vscode
    vlc
    (pkgs.kodi.withPackages (kodiPkgs: with kodiPkgs; [
      jellyfin
      inputstream-adaptive
      pvr-iptvsimple
    ]))
  ];


  xdg.configFile = builtins.mapAttrs
    (name: subpath: {
      source = create_symlink "${dotfiles}/${subpath}";
      recursive = true;
    })
    configs;

}
