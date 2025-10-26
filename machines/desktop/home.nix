{ config, pkgs, ... }:

{
  home.username = "david";
  home.homeDirectory = "/home/david";
  home.stateVersion = "25.05";
  programs.bash = {
    enable = true;
    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake /etc/nixos";
      ncs = "sudo nix-collect-garbage; sudo nix-collect-garbage -d; sudo nixos-rebuild switch --flake /etc/nixos";
      nix-upgrade = "nix flake update /etc/nixos && sudo nixos-rebuild switch --flake /etc/nixos";
    };
    initExtra = ''
      export PS1='\[\e[38;5;76m\]\u\[\e[0m\] in \[\e[38;5;32m\]\w\[\e[0m\] \\$ '
      nitch
    '';
  };

  home.packages = with pkgs; [
    nitch
    obsidian
    vscode
    # nixfmt-rfc-style
    git
    discord
    plexamp
    spotify
    gimp
    freecad
    ansible
    prismlauncher
    brave
    dolphin-emu
    winboat
    vlc
    pcsx2
    rpcs3
    sm64coopdx
  ];

}
