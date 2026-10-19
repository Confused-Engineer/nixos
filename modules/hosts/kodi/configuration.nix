# Kodi HTPC. Default boot is Kodi-only; the `desktop` specialisation gives
# you a regular cosmic session for maintenance/admin work.
#
# Cheat-sheet: setting volume from another user's session:
#   sudo -u kodi XDG_RUNTIME_DIR=/run/user/$(id -u kodi) \
#     wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.0
{
  inputs,
  self,
  config,
  ...
}:
let
  inherit (config) sshKeys;
in
{
  flake.nixosConfigurations.kodi = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ self.modules.nixos.kodi ];
  };

  flake.modules.nixos.kodi =
    { config, pkgs, ... }:
    {
      # Only settings-common — kodi defines its own user and auto-upgrade
      # schedule below, so it deliberately skips settings-baseline.
      imports = with self.modules.nixos; [
        nixpkgs
        binary-cache

        boot
        de-kodi
        gc
        settings-common
      ];

      specialisation.desktop.configuration = {
        imports = with self.modules.nixos; [
          firefox
          de-cosmic
        ];

        custom = {
          # Swap the Kodi session for COSMIC.
          de-kodi.enable = false;

          firefox = {
            privacy = "strict";
            homepage = "https://hp.a5f.org/";
          };

          de-cosmic = {
            strip.enable = true;
            nvidiaFix.hibernate = false;
          };
        };
        environment.systemPackages = with pkgs; [
          vscode
        ];
      };

      custom.boot = {
        fancy.enable = true;
        fancy.secureBoot = false;
        systemd = false;
      };

      environment.systemPackages = with pkgs; [
        git
      ];

      boot.kernelPackages = pkgs.linuxPackages_latest;

      # Kodi auto-upgrades unattended (it's a TV — reboot when the wife isn't
      # watching). The other hosts use the baseline schedule.
      system.autoUpgrade = {
        enable = true;
        flake = "github:Confused-Engineer/nixos#${config.networking.hostName}";
        flags = [
          "--refresh"
          "--no-write-lock-file"
        ];
        dates = "*-*-01 02:00:00";
        operation = "boot";
        randomizedDelaySec = "30min";
        allowReboot = true;
      };

      networking.hostName = "kodi";
      networking.networkmanager.enable = true;
      nix.settings.trusted-users = [
        "root"
        "david"
      ];

      services.printing.enable = false;

      services.openssh = {
        enable = true;
        settings.PasswordAuthentication = true;
        settings.AllowUsers = [
          "david"
          "root"
        ];
        settings.PermitRootLogin = "prohibit-password";
      };

      users.users = {
        david = {
          isNormalUser = true;
          description = "david";
          extraGroups = [
            "networkmanager"
            "wheel"
          ];
          openssh.authorizedKeys.keys = sshKeys.david;
        };
        root.openssh.authorizedKeys.keys = sshKeys.david;
      };

      system.stateVersion = "25.11";
    };
}
