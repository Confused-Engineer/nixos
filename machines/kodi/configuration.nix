# Kodi HTPC. Default boot is Kodi-only; the `desktop` specialisation gives
# you a regular cosmic session for maintenance/admin work.
#
# Cheat-sheet: setting volume from another user's session:
#   sudo -u kodi XDG_RUNTIME_DIR=/run/user/$(id -u kodi) \
#     wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.0

{ config, pkgs, ... }:
let
  keys = import ./../../users/keys.nix;
in {
  imports = [
    ./hardware-configuration.nix
    ./specialisation-default.nix
  ./../../nixosModules
  ];

  specialisation.desktop.configuration = {
    custom = {
      apps.browsers.firefox = {
        enable   = true;
        privacy  = "strict";
        homepage = "https://hp.int.a5f.org/";
      };

      os.ui.cosmic = {
        enable              = true;
        strip.enable        = true;
        nvidiaFix.hibernate = false;
      };
    };
    environment.systemPackages = with pkgs; [
      vscode
    ];
  };

  custom.boot = {
    enable           = true;
    fancy.enable     = true;
    fancy.secureBoot = false;
    systemd          = false;
  };

  environment.systemPackages = with pkgs; [
    git
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Kodi auto-upgrades unattended (it's a TV — reboot when the wife isn't
  # watching). The other hosts use the baseline schedule.
  system.autoUpgrade = {
    enable             = true;
    flake              = "github:Confused-Engineer/nixos#${config.networking.hostName}";
    flags              = [ "--refresh" "--no-write-lock-file" ];
    dates              = "*-*-01 02:00:00";
    operation          = "switch";
    randomizedDelaySec = "30min";
    allowReboot        = true;
  };

  networking.hostName              = "kodi";
  networking.networkmanager.enable = true;
  nix.settings.trusted-users       = [ "root" "david" ];

  time.timeZone      = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS        = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT    = "en_US.UTF-8";
    LC_MONETARY       = "en_US.UTF-8";
    LC_NAME           = "en_US.UTF-8";
    LC_NUMERIC        = "en_US.UTF-8";
    LC_PAPER          = "en_US.UTF-8";
    LC_TELEPHONE      = "en_US.UTF-8";
    LC_TIME           = "en_US.UTF-8";
  };

  services.xserver.xkb = {
    layout  = "us";
    variant = "";
  };

  services.printing.enable   = false;
  services.pulseaudio.enable = false;
  security.rtkit.enable      = true;
  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
  };

  services.openssh = {
    enable                          = true;
    settings.PasswordAuthentication = true;
    settings.AllowUsers              = [ "david" "root" ];
    settings.PermitRootLogin         = "prohibit-password";
  };

  users.users = {
    david = {
      isNormalUser                = true;
      description                 = "david";
      extraGroups                 = [ "networkmanager" "wheel" ];
      openssh.authorizedKeys.keys = keys.david;
    };
    root.openssh.authorizedKeys.keys = keys.david;
  };

  system.stateVersion = "25.11";
}
