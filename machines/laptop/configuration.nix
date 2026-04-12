# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./../../nixosModules
    ];

  
  custom = {
    apps = {
      steam.enable = false; # Enable Steam
      steam.systemd.enable = true; # Start Steam on Login
      flatpaks = {
        enable = true;
        update = true;
        desiredFlatpaks = [
          "com.github.tchx84.Flatseal"
          "com.bambulab.BambuStudio"
        ];
      };

      browsers.firefox = {
        enable = true;
        privacy = "strict";
        homepage = "https://hp.int.a5f.org/";
      };
    };

    hardware.gpu.nvidia.enable = false;
    hardware.controllers.xbox.enable = true;

    os = {
      autoClean.enable = true; # Clean System images greater than 7 days old
      autoUpgrade.enable = true;

      ui = {
        gnome = {
          enable = false; # Use gnome
          strip.enable = true;
          extensions.enable = true;
          nvidiaFix.hibernate = true;
        };

        kde = {
          enable = false; # Use gnome
          strip.enable = true;
        };

        cosmic = {
          enable = true; # Use gnome
          strip.enable = true;
          nvidiaFix.hibernate = false;
        };
      };
    };

    systemd = {
      system_api.enable = false; # Enable System API For Home Assistant
      shizukuLinux.enable = false; # Enable starting shizuku on android device plugin
    };

    
    
  };


  specialisation = {
    lid-no-sleep = {
      inheritParentConfig = true;
      configuration = {
        services.logind.settings.Login.HandleLidSwitchDocked = "ignore"; 
        services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore"; 

      };
    };

  };

  services.mullvad-vpn.enable = true;
  services.mullvad-vpn.package = pkgs.mullvad-vpn;
  #services.fwupd.enable = true;
  programs.kdeconnect.enable = true;


  nix.settings.experimental-features = ["nix-command" "flakes"];


  boot = {
    loader = {
      systemd-boot.enable = false;
      limine.enable = true;
      efi.canTouchEfiVariables = true;

    };

    plymouth = {
      enable = true;
      theme = "circle";
      themePackages = with pkgs; [
        # By default we would install all themes
        (adi1090x-plymouth-themes.override {
          selected_themes = [ "circle" ];
        })
      ];
    };
    
    initrd.systemd.enable = true;
    consoleLogLevel = 0;

    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ "quiet" "splash" "boot.shell_on_fail" ];
    kernelModules = [ "ntsync" ];
  };


  networking.hostName = "laptop"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

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

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

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
    description = "David Pierce";
    initialPassword = "vmtest";
    extraGroups = [ "networkmanager" "dialout" "wheel" "audio" "openrazer" "power" "docker"];
    packages = with pkgs; [
      tree
    ];
  };


  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.packageOverrides = pkgs: {
    jellyfin2samsung = pkgs.callPackage ./../../nixosModules/apps/custom/Jellyfin2Samsung/package.nix { };
  };

  environment.systemPackages = with pkgs; [
    jellyfin2samsung
    git 
    zsh
    zsh-completions
    pavucontrol
    gparted
    # winboat
  ];

  services.logind.settings.Login.HandleLidSwitch = "hibernate";
  # services.logind.lidSwitch = "hibernate";

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    fira-sans
    fira-code
    nerd-fonts.fira-code
    font-awesome
    material-design-icons
  ];

  services.power-profiles-daemon.enable = true;
  powerManagement.enable = true;


  hardware.graphics.extraPackages = with pkgs; [ intel-vaapi-driver intel-media-driver ];
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
  networking.firewall = {
    allowedTCPPorts = [ 8080 ];
    allowedUDPPorts = [ 8080 ];
  };
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
