{ config, pkgs, ... }:
{
  programs.bash = {
    enable = true;
    shellAliases = {
      nix-switch = "sudo nixos-rebuild switch --flake /etc/nixos";
      nix-boot = "sudo nixos-rebuild boot --flake /etc/nixos";
      nix-test = "sudo nixos-rebuild build-vm --flake /etc/nixos";
      nix-upgrade = "sudo nix flake update --flake /etc/nixos && sudo nixos-rebuild build-vm --flake /etc/nixos";
      nix-clean = "sudo nix-collect-garbage; sudo nix-collect-garbage -d; sudo nixos-rebuild boot --flake /etc/nixos";
    };
  };
}