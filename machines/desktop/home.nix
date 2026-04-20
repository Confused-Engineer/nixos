{ config, pkgs, ... }:
let
  config_dir = "/etc/nixos/machines/desktop/home/.config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
  configs = {
    #MangoHud = "MangoHud";
    autostart = "autostart";
  };
in
{

  imports = [
    ./../../nixosModules/home-manager
  ];

  custom = {
    shell.bash = {
      enable = true;
      fancy = true;
      nixosAlias = true;
      startHyprland = false;
    };
    mangohud.enable = true;
  };

  home.username = "david";
  home.homeDirectory = "/home/david";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    brave
    gimp
    git
    obsidian
    prismlauncher
    spotify
    vlc
    vscode
  ];

  # In your configuration.nix or home-manager config
  home.file.".local/share/flatpak/overrides/com.core447.StreamController".text = ''
    [Context]
    filesystems=/run/user/1000;
  '';

  home.file.".local/share/Steam/steam_dev.cfg".text = ''
    unShaderBackgroundProcessingThreads 16
  '';

  xdg.configFile = builtins.mapAttrs (name: subpath: {
    source = create_symlink "${config_dir}/${subpath}";
    recursive = true;
  }) configs;

}
