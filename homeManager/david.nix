{
  config,
  pkgs,
  inputs,
  lib,
  hostname ? null,
  ...
}:
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

    # Only enable the Stream Deck stack on the desktop. The previous shared
    # config silently autostarted StreamController on every machine.
    streamcontroller.enable = hostname == "desktop";
    steam.steamShaderThreads = if hostname == "desktop" then 16 else null;
  };

  home.username = "david";
  home.homeDirectory = "/home/david";
  home.stateVersion = "25.11";

  home.file.".aider.conf.yml".text = ''
    model: ollama/gemma4:e4b

    set-env:
      - OLLAMA_API_BASE=http://10.87.10.21:11434

    auto-commits: false
    dirty-commits: true

    pretty: true
    stream: true

    map-tokens: 512
    map-refresh: files
    max-chat-history-tokens: 2048
    suggest-shell-commands: false
  '';

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
    nixd
    zsh
    zsh-completions
    qFlipper
    inputs.claude-code-nix.packages.${pkgs.system}.default
    # inputs.claude-code-nix.packages.${pkgs.system}.claude-code-fhs
    aider-chat
    apps2samsung

    (pkgs.kodi.withPackages (
      kp: with kp; [
        jellyfin
        inputstream-adaptive
      ]
    ))
  ];
}
