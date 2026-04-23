{ lib, pkgs, config, ... }:                      
let
  # Shorter name to access final settings a 
  # user of hello.nix module HAS ACTUALLY SET.
  # cfg is a typical convention.
  cfg = config.custom.shell.bash;
in {
  # Declare what settings a user of this "hello.nix" module CAN SET.
  options.custom.shell.bash = {
    
    enable = lib.mkEnableOption "enable bash option";
  
    fancy = lib.mkEnableOption "nitch";
    nixosAlias = lib.mkEnableOption "Nixos-Rebuild alias's";
    startHyprland = lib.mkEnableOption "Start hyprland on login";



  };
  # Define what other settings, services and resources should be active IF
  # a user of this "hello.nix" module ENABLED this module 
  # by setting "services.hello.enable = true;".
  config = lib.mkIf cfg.enable {
    programs.bash = {
      enable = true;
      shellAliases = lib.mkIf (cfg.nixosAlias == true ) {
        nix-switch = "sudo nixos-rebuild switch --flake /etc/nixos";
        nix-boot = "sudo nixos-rebuild boot --flake /etc/nixos";
        nix-test = "sudo nixos-rebuild build-vm --flake /etc/nixos";
        nix-upgrade = "sudo nix flake update --flake /etc/nixos && sudo nixos-rebuild build-vm --flake /etc/nixos";
        nix-clean = "sudo nix-collect-garbage; sudo nix-collect-garbage -d; sudo nixos-rebuild boot --flake /etc/nixos";
        nix-remote = ''
          read -p "Target Hostname: " TargetHostname
          read -p "Target IP: " TargetIP
          nixos-rebuild boot --flake /etc/nixos#"''${TargetHostname}" --target-host "''${TargetIP}" --sudo --ask-sudo-password
        '';
      };
      initExtra = lib.mkIf (cfg.fancy == true ) ''
        export PS1='\[\e[38;5;76m\]\u\[\e[0m\] in \[\e[38;5;32m\]\w\[\e[0m\] \\$ '
        nitch
      '';
      profileExtra = lib.mkIf (cfg.startHyprland == true ) ''
        if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
          exec uwsm start hyprland-uwsm.desktop
        fi
      '';

    };
    home.packages = with pkgs; lib.mkIf (cfg.fancy == true ) [
      nitch
    ];
  };

}