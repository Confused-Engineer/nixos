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
          "org.onlyoffice.desktopeditors"
          "com.github.tchx84.Flatseal"
          "com.bambulab.BambuStudio"
        ];
      };

      browsers.firefox = {
        enable = true;
        privacy = "strict";
        homepage = "https://hp.a5f.org/";
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

  #programs.hyprland = {
  #  enable = true;
  #  xwayland.enable = true;
  #  withUWSM = true;
  #};

  services.mullvad-vpn.enable = true;
  services.mullvad-vpn.package = pkgs.mullvad-vpn;


 # networking.nameservers = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];
 # services.resolved = {
 #   enable = true;
 #   dnssec = "true";
 #   domains = [ "~." ];
 #   fallbackDns = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];
 #   dnsovertls = "true";
 # };

  nix.settings.experimental-features = ["nix-command" "flakes"];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "laptop"; # Define your hostname.
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
    extraGroups = [ "networkmanager" "wheel" "audio" "openrazer" "power" "docker"];
    packages = with pkgs; [
      tree
    ];
  };

  virtualisation.docker = {
    enable = true;
  };
  # Install firefox.
  # programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git 
    zsh
    zsh-completions
    pavucontrol
    # (winboat.override { electron = pkgs.electron_37; })
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
  # Optional settings:
  # services.logind.lidSwitchExternalPower = "hibernate"; # Hibernate when on external power
  # services.logind.lidSwitchDocked = "ignore"; # Don't hibernate when docked
  services.power-profiles-daemon.enable = true;
  powerManagement.enable = true;
  #services.tlp = {
  #  enable = true;
  #  settings = {
  #    CPU_SCALING_GOVERNOR_ON_AC = "performance";
  #    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
#
  #    CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
  #    CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
#
  #    CPU_MIN_PERF_ON_AC = 0;
  #    CPU_MAX_PERF_ON_AC = 100;
  #    CPU_MIN_PERF_ON_BAT = 0;
  #    CPU_MAX_PERF_ON_BAT = 20;
#
  #    #Optional helps save long term battery health
  #    START_CHARGE_THRESH_BAT0 = 50; # 40 and below it starts to charge
  #    STOP_CHARGE_THRESH_BAT0 = 85; # 80 and above it stops charging
#
  #  };
  #};

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
  system.stateVersion = "25.05"; # Did you read the comment?

}
