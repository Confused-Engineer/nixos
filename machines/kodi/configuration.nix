# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
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
            homepage = "https://hp.a5f.org/";
          };
        };

        os = {
          autoClean.enable = true; # Clean System images greater than 7 days old
          autoUpgrade.enable = true;

          ui = {
            cosmic = {
              enable = true; # Use gnome
              strip.enable = true;
              nvidiaFix.hibernate = false;
            };
          };
        };    
      };

      environment.systemPackages = with pkgs; [
      #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      #  wget
        vscode
        git
      ];
      
    };


  };




  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "kodi"; # Define your hostname.
  nix.settings.trusted-users = [ "root" "david" ];
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
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




  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
    settings.AllowUsers = [ "david" ];
    settings.PermitRootLogin = "prohibit-password";
  };




  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = false;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.david = {
    isNormalUser = true;
    description = "david";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
    ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDFpKE1DjAc7J+2cJuns84/gZIpNxbch1oYh/UeYbiiDbTMVGMMh8KGCKAhrJ9LO1aEyZxcfBlA2KyMRSnam4GUPGv4M+a9f0j/Bxs0m8Lwc+wWKMMuKhkJrGn8nKZUO7gjRUZevUFGvIe2lOp3L5RggPNewQ4hpLmn4Uf2Ywh8n6bdUZDAEdd4ut9IgRKFr9bQsLvgMA3cD7Ot66rbkplPvTmIuV4Qo8W8E3l2VpH6UHAl0nwpkDCOYEnSe32iSuewygGb13ZRa6jrEbrsLmI5pPfMitNGNVGnEPpKBC/dw8MJ4p8e302TJKNpnizHXnwPvxIT1D+/kygj8ob0D2YlySfI5bNeuXcZS86cthtI5Y0LDZqngQgsOr3mIIBl0dAxV44ytyqdVYqtoXgND4MvEHy+ur7QEEuWK7gZMh/g1yjllFV15chfnudlJqz7zS6lGA8drF58Sl5ipNQrCw56pT3vJs2eCtLagP16BCKm60ciSEL88QMxFqH3oGi1tn8= david" # content of authorized_keys file
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC1HxS3MUEqEsTRSoHaFjMoHZme0Na9BpCH4fjtNyp3s2OtOC5u335QRGkeGyMZW5QDVWkEpfyL1+TB097mGP2akeVitv7A47p4ErGqogM8oWtZywzANz8t7G6VgIOvp1Qdi9Q5nQSQuaFrS6SCE4SWpuTYlzvy40hFIn884NivMfCOJpQAShMrQgDgC9R/xK852O10AptX0nc0qVzSraya8KmIDFpOgdbPonpDPSaaUbo7u4RDs7lXn6YdwxvqhtQw/inydvkBi0SmFSTnjci9xVrJsVjjYwPn50HJhAhe/Z9v1ZbW8mSYw0merrgAGn3HNBR6GlQnujw0Ejlov4KKq1Px5RjrIUp9yb4UCaENf1w2wMhezrlouuWKbehQwrx5+9ltJLRy7lU5jlv7AJDYcyvkt3bzVXqtPsMtNsxD7Aa6ivkokOefnj+5CyE5IdgBOE3JoHtDjdlkhDy3hAPurTwBcAe103jjI+cGTMn0Blf2FX4KPeqS85UmS2UC0f8= david"
      # note: ssh-copy-id will add user@your-machine after the public key
      # but we can remove the "@your-machine" part
    ];

  };


  # Allow unfree packages
  
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
