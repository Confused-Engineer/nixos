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
    ./../modules
  ];

  custom = {
    bash = {
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

  # The GA104 (desktop GPU) HDMI audio card reports all three HDMI ports as
  # "available" at once, so WirePlumber's profile-restore is unreliable across
  # logins/resume and keeps falling back away from the correct HDMI1 output,
  # requiring a manual fix in pavucontrol. Force it back on every pipewire
  # start and every resume from sleep.
  systemd.user.services.fix-hdmi-audio-profile = lib.mkIf (hostname == "desktop") {
    Unit = {
      Description = "Pin GA104 HDMI audio card to the correct HDMI1 profile";
      After = [
        "pipewire.service"
        "wireplumber.service"
        "sleep.target"
      ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = toString (
        pkgs.writeShellScript "fix-hdmi-audio-profile" ''
          card="alsa_card.pci-0000_09_00.1"
          profile="output:hdmi-stereo"
          for i in $(seq 1 20); do
            ${pkgs.pulseaudio}/bin/pactl list cards short | grep -q "$card" && break
            sleep 0.5
          done
          ${pkgs.pulseaudio}/bin/pactl set-card-profile "$card" "$profile"
        ''
      );
    };
    Install.WantedBy = [
      "pipewire.service"
      "sleep.target"
    ];
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

    #(pkgs.kodi.withPackages (
    #  kp: with kp; [
    #    jellyfin
    #    inputstream-adaptive
    #  ]
    #))
  ];
}
