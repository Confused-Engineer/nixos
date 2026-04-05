{ config, pkgs, ... }:

{
  home.username = "david";
  home.homeDirectory = "/home/david";
  home.stateVersion = "25.11";
  programs.bash = {
    enable = true;
    shellAliases = {
      nix-switch = "sudo nixos-rebuild switch --flake /etc/nixos";
      nix-boot = "sudo nixos-rebuild boot --flake /etc/nixos";
      nix-test = "sudo nixos-rebuild build-vm --flake /etc/nixos";
      nix-upgrade = "sudo nix flake update --flake /etc/nixos && sudo nixos-rebuild build-vm --flake /etc/nixos";
      nix-clean = "sudo nix-collect-garbage; sudo nix-collect-garbage -d; sudo nixos-rebuild boot --flake /etc/nixos";
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
    git
    
    
    spotify
    gimp
    
    prismlauncher
    brave
    vlc
  ];

  # In your configuration.nix or home-manager config
  home.file.".local/share/flatpak/overrides/com.core447.StreamController".text = ''
    [Context]
    filesystems=/run/user/1000;
  '';

}
