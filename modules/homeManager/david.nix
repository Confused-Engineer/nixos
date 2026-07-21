# Shared Home-Manager profile for `david` (was homeManager/david.nix). The HM
# custom option-modules are imported alongside this by the nixos-side wiring
# (modules/nixos/home-manager.nix), so this file just sets values + packages.
{
  flake.modules.homeManager.david =
    {
      config,
      pkgs,
      inputs,
      lib,
      hostname ? null,
      ...
    }:
    {
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

      home.packages = with pkgs; [
        brave
        baobab
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
        inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
        # inputs.claude-code-nix.packages.${pkgs.system}.claude-code-fhs
        apps2samsung

        #(pkgs.kodi.withPackages (
        #  kp: with kp; [
        #    jellyfin
        #    inputstream-adaptive
        #  ]
        #))
      ];
    };
}
