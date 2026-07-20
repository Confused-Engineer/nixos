# kodi — HTPC. STABLE nixpkgs, no home-manager, both binary caches.
# Default boot is Kodi-only; the `desktop` specialisation gives a cosmic
# session for maintenance. Uses `common` but not `baseline` (own user +
# auto-upgrade schedule).
#
# Cheat-sheet: setting volume from another user's session:
#   sudo -u kodi XDG_RUNTIME_DIR=/run/user/$(id -u kodi) \
#     wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.0
{ config, inputs, ... }:
let
  nixos = config.flake.modules.nixos;
  keys = import ../../users/keys.nix;
in
{
  flake.nixosConfigurations.kodi = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      nixos.base
      nixos.common
      nixos.custom
      nixos.binaryCache
      nixos.cudaCache

      ../../machines/kodi/hardware-configuration.nix
      # Enables the Kodi session only on the default boot (not the desktop spec).
      ../../machines/kodi/specialisation-default.nix

      (
        { config, pkgs, ... }:
        {
          specialisation.desktop.configuration = {
            custom = {
              apps.browsers.firefox = {
                enable = true;
                privacy = "strict";
                homepage = "https://hp.int.a5f.org/";
              };

              os.ui.cosmic = {
                enable = true;
                strip.enable = true;
                nvidiaFix.hibernate = false;
              };
            };
            environment.systemPackages = with pkgs; [
              vscode
            ];
          };

          custom.boot = {
            enable = true;
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
            operation = "switch";
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
              openssh.authorizedKeys.keys = keys.david;
            };
            root.openssh.authorizedKeys.keys = keys.david;
          };

          system.stateVersion = "25.11";
        }
      )
    ];
  };
}
