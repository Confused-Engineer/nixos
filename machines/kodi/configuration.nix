# sudo -u kodi XDG_RUNTIME_DIR=/run/user/$(id -u kodi) wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.0
# set system volume from terminal of other user 
{ config, pkgs, ... }:
let
  sshKeys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDFpKE1DjAc7J+2cJuns84/gZIpNxbch1oYh/UeYbiiDbTMVGMMh8KGCKAhrJ9LO1aEyZxcfBlA2KyMRSnam4GUPGv4M+a9f0j/Bxs0m8Lwc+wWKMMuKhkJrGn8nKZUO7gjRUZevUFGvIe2lOp3L5RggPNewQ4hpLmn4Uf2Ywh8n6bdUZDAEdd4ut9IgRKFr9bQsLvgMA3cD7Ot66rbkplPvTmIuV4Qo8W8E3l2VpH6UHAl0nwpkDCOYEnSe32iSuewygGb13ZRa6jrEbrsLmI5pPfMitNGNVGnEPpKBC/dw8MJ4p8e302TJKNpnizHXnwPvxIT1D+/kygj8ob0D2YlySfI5bNeuXcZS86cthtI5Y0LDZqngQgsOr3mIIBl0dAxV44ytyqdVYqtoXgND4MvEHy+ur7QEEuWK7gZMh/g1yjllFV15chfnudlJqz7zS6lGA8drF58Sl5ipNQrCw56pT3vJs2eCtLagP16BCKm60ciSEL88QMxFqH3oGi1tn8= david" # content of authorized_keys file
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC1HxS3MUEqEsTRSoHaFjMoHZme0Na9BpCH4fjtNyp3s2OtOC5u335QRGkeGyMZW5QDVWkEpfyL1+TB097mGP2akeVitv7A47p4ErGqogM8oWtZywzANz8t7G6VgIOvp1Qdi9Q5nQSQuaFrS6SCE4SWpuTYlzvy40hFIn884NivMfCOJpQAShMrQgDgC9R/xK852O10AptX0nc0qVzSraya8KmIDFpOgdbPonpDPSaaUbo7u4RDs7lXn6YdwxvqhtQw/inydvkBi0SmFSTnjci9xVrJsVjjYwPn50HJhAhe/Z9v1ZbW8mSYw0merrgAGn3HNBR6GlQnujw0Ejlov4KKq1Px5RjrIUp9yb4UCaENf1w2wMhezrlouuWKbehQwrx5+9ltJLRy7lU5jlv7AJDYcyvkt3bzVXqtPsMtNsxD7Aa6ivkokOefnj+5CyE5IdgBOE3JoHtDjdlkhDy3hAPurTwBcAe103jjI+cGTMn0Blf2FX4KPeqS85UmS2UC0f8= david"
  ];
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./default-only.nix
      ./../../nixosModules
    ];

  specialisation = {
    desktop.configuration = {

      custom = {
        apps = {
          browsers.firefox = {
            enable = true;
            privacy = "strict";
            homepage = "https://hp.int.a5f.org/";
          };
        };

        os = {
          ui = {
            cosmic = {
              enable = true;
              strip.enable = true;
              nvidiaFix.hibernate = false;
            };
          };
        };    
      };

      environment.systemPackages = with pkgs; [
        vscode
        git
      ];
    };
  };

  
  custom.boot = {
    enable = true;
    fancy.enable = true;
    fancy.secureBoot = false;
    systemd = false;
  };
  
  boot.loader.efi.canTouchEfiVariables = true;
  kernelPackages = pkgs.linuxPackages;
  system.autoUpgrade = {
    enable = true;
    flake = "github:Confused-Engineer/nixos#${config.networking.hostName}";
    flags = [ "--refresh" "--no-write-lock-file" ];
    dates = "*-*-01 2:00:00";
    operation = "switch";
    randomizedDelaySec = "30min";
    allowReboot = true;
  };

  networking.hostName = "kodi"; # Define your hostname.
  nix.settings.trusted-users = [ "root" "david" ];

  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };



  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.printing.enable = false;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
    settings.AllowUsers = [ "david" "root"];
    settings.PermitRootLogin = "prohibit-password";
  };

  users.users = {
    david = {
      isNormalUser = true;
      description = "david";
      extraGroups = [ "networkmanager" "wheel" ];

      openssh.authorizedKeys.keys = sshKeys;
    };

    root.openssh.authorizedKeys.keys = sshKeys;
  };

  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "25.11"; # Did you read the comment?

}
