{ lib, pkgs, config, ... }:
let
  cfg = config.custom.shell.bash;
in {
  options.custom.shell.bash = {
    enable        = lib.mkEnableOption "managed bash configuration";
    fancy         = lib.mkEnableOption "colorful PS1 + nitch on shell start";
    nixosAlias    = lib.mkEnableOption "convenience aliases for nixos-rebuild";
    startHyprland = lib.mkEnableOption "auto-start hyprland on tty1";
  };

  config = lib.mkIf cfg.enable {
    programs.bash = {
      enable = true;

      shellAliases = lib.mkIf cfg.nixosAlias {
        nix-switch  = "sudo nixos-rebuild switch    --flake /etc/nixos";
        nix-boot    = "sudo nixos-rebuild boot      --flake /etc/nixos";
        nix-test    = "sudo nixos-rebuild test      --flake /etc/nixos";
        nix-vm      = "sudo nixos-rebuild build-vm  --flake /etc/nixos";
        nix-git     = "sudo nixos-rebuild switch    --flake github:Confused-Engineer/nixos --refresh";
        nix-upgrade = "sudo nix flake update --flake /etc/nixos && sudo nixos-rebuild build-vm --flake /etc/nixos";
        nix-clean   = "sudo nix-collect-garbage; sudo nix-collect-garbage -d; sudo nixos-rebuild boot --flake /etc/nixos";
        nix-remote  = ''
          read -p "Target Hostname: " TargetHostname
          read -p "Target IP: " TargetIP
          nixos-rebuild boot --flake /etc/nixos#"''${TargetHostname}" --target-host root@"''${TargetIP}"
        '';
      };

      initExtra = lib.mkIf cfg.fancy ''
        export PS1='\[\e[38;5;76m\]\u\[\e[0m\] in \[\e[38;5;32m\]\w\[\e[0m\] \\$ '
        nitch
      '';

      profileExtra = lib.mkIf cfg.startHyprland ''
        if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
          exec uwsm start hyprland-uwsm.desktop
        fi
      '';
    };

    home.packages = lib.mkIf cfg.fancy [ pkgs.nitch ];
  };
}
