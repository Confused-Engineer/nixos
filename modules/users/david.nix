# david's home-manager config. It is part of the `home-manager` aspect
# (together with modules/base/home-manager.nix), so every host that imports
# that aspect gets it. Host-specific additions live with the host, e.g.
# modules/hosts/desktop/home.nix.
#
# This is set as `home-manager.users.david` directly rather than published
# as a `flake.modules.homeManager.david` aspect: keeping it a direct
# definition keeps its `home.packages` ordered after home-manager's own,
# exactly as before the dendritic move (order changes the derivation).
{ inputs, self, ... }:
{
  flake.modules.nixos.home-manager.home-manager.users.david =
    { pkgs, ... }:
    {
      imports = with self.modules.homeManager; [
        bash
        mangohud
      ];

      custom.bash = {
        fancy = true;
        nixosAlias = true;
        startHyprland = false;
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
        # moonlight-qt # temp disable until ffmpeg fix
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
        nixpkgs-tracker
        feishin

        #(pkgs.kodi.withPackages (
        #  kp: with kp; [
        #    jellyfin
        #    inputstream-adaptive
        #  ]
        #))
      ];
    };
}
