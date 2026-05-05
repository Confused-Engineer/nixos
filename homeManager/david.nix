{ config, pkgs, lib, hostname ? null, ... }:
{
  imports = [
    ./../nixosModules/home-manager
  ];

  custom = {
    shell.bash = {
      enable        = true;
      fancy         = true;
      nixosAlias    = true;
      startHyprland = false;
    };
    mangohud.enable = true;

    # Only enable the Stream Deck stack on the desktop. The previous shared
    # config silently autostarted StreamController on every machine.
    streamcontroller = {
      enable             = hostname == "desktop";
      steamShaderThreads = if hostname == "desktop" then 16 else null;
    };
  };

  home.username      = "david";
  home.homeDirectory = "/home/david";
  home.stateVersion  = "25.11";

  home.packages = with pkgs; [
    brave
    discord
    gimp
    jellyfin2samsung
    onlyoffice-desktopeditors
    moonlight-qt
    nixfmt
    nixfmt-tree
    obsidian
    pavucontrol
    prismlauncher
    spotify
    vlc
    vscode
    zsh
    zsh-completions

    (pkgs.kodi.withPackages (kp: with kp; [
      jellyfin
      inputstream-adaptive
    ]))
  ];
}
