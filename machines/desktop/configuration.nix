# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

# Notes:
# On Wayland with Bambu
# Use the flatpak and flatseal to se environment variables as such if you have nvidia and encounter errors:
# __EGL_VENDOR_LIBRARY_FILENAMES=/usr/lib/x86_64-linux-gnu/GL/default/share/glvnd/egl_vendor.d/50_mesa.json
# WEBKIT_DISABLE_DMABUF_RENDERER=1
# GALLIUM_DRIVER=zink
# MESA_LOADER_DRIVER_OVERRIDE=zink
# __GLX_VENDOR_LIBRARY_NAME=mesa
# 


{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./../../nixosModules
    ];


  custom = {
    apps = {
      steam.enable = true; # Enable Steam
      steam.systemd.enable = true; # Start Steam on Login
      flatpaks = {
        enable = true;
        update = false;
        desiredFlatpaks = [
          "org.onlyoffice.desktopeditors"
          "com.github.tchx84.Flatseal"
          "at.vintagestory.VintageStory"
          "com.usebottles.bottles"
          "com.bambulab.BambuStudio"
        ];
      };

      browsers.firefox = {
        enable = true;
        DisableFirefoxAccounts = false;
        privacy = "strict";
        homepage = "https://hp.a5f.org/";
      };
    };

    hardware.gpu.nvidia.enable = true;
    hardware.controllers.xbox.enable = true;

    os = {
      autoClean.enable = true; # Clean System images greater than 7 days old
      autoUpgrade.enable = true;

      ui = {
        gnome = {
          enable = true; # Use gnome
          strip.enable = true;
          extensions.enable = true;
          disable.hibernate = false;
        };

        cosmic = {
          enable = false; # Use gnome
          strip.enable = true;
          extensions.enable = true;
          disable.hibernate = false;
        };
      };
    };

    systemd = {
      system_api.enable = true; # Enable System API For Home Assistant
      shizukuLinux.enable = false; # Enable starting shizuku on android device plugin
    };
    
  };


  services.sunshine = {
    enable = false;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
    
  };

  
  # Flakes
  nix.settings.experimental-features = ["nix-command" "flakes"];




  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  ### ZFS SUPPORT ###
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  networking.hostId = "93d0703e";
  boot.postBootCommands = ''
    ${pkgs.zfs}/bin/zpool import -a
    ${pkgs.zfs}/bin/zfs mount -a
'';



  networking.hostName = "desktop"; # Define your hostname.
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
    description = "david";
    extraGroups = [ "networkmanager" "wheel" "audio" "openrazer" "dialout"];
    packages = with pkgs; [
    #  thunderbird
    ];
  };


  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    discord
    heroic
    freecad
    unstable.r2modman
    pavucontrol
    vscode
    mangohud
    spotify
    plexamp
    neofetch
    git
    bash
    rustup
    gcc
    ansible
    prismlauncher
    polychromatic
    openrazer-daemon
    brave
    procps
    gparted
    audacity
    dolphin-emu
    unstable.lact
    vlc
  ];
  
  systemd.services.lact = {
    description = "AMDGPU Control Daemon";
    after = ["multi-user.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStart = "${pkgs.unstable.lact}/bin/lact daemon";
    };
    enable = true;
  };
  hardware.openrazer.enable = true;


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
################ SERVICES ####################



  systemd.services.copyGdmMonitorsXml = {
    description = "Copy monitors.xml to GDM config";
    after = [ "network.target" "systemd-user-sessions.service" "display-manager.service" ];
    serviceConfig = {
      ExecStart = "${pkgs.bash}/bin/bash -c 'echo \"Running copyGdmMonitorsXml service\" && mkdir -p /run/gdm/.config && echo \"Created /run/gdm/.config directory\" && [ \"/home/david/.config/monitors.xml\" -ef \"/run/gdm/.config/monitors.xml\" ] || cp /home/david/.config/monitors.xml /run/gdm/.config/monitors.xml && echo \"Copied monitors.xml to /run/gdm/.config/monitors.xml\" && chown gdm:gdm /run/gdm/.config/monitors.xml && echo \"Changed ownership of monitors.xml to gdm\"'";
      Type = "oneshot";
    };
    wantedBy = [ "multi-user.target" ];
  };



  systemd = {
     services."gnome-suspend" = {
      description = "suspend gnome shell";
      before = [
        "systemd-suspend.service" 
        "systemd-hibernate.service"
        "nvidia-suspend.service"
        "nvidia-hibernate.service"
      ];
      wantedBy = [
        "systemd-suspend.service"
        "systemd-hibernate.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ''${pkgs.procps}/bin/pkill -f -STOP ${pkgs.gnome-shell}/bin/gnome-shell'';
      };
    };
    services."gnome-resume" = {
      description = "resume gnome shell";
      after = [
        "systemd-suspend.service" 
        "systemd-hibernate.service"
        "nvidia-resume.service"
      ];
      wantedBy = [
        "systemd-suspend.service"
        "systemd-hibernate.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ''${pkgs.procps}/bin/pkill -f -CONT ${pkgs.gnome-shell}/bin/gnome-shell'';
      };
    };
  };

################ DRIVES ######################
# last blkid dump
# /dev/nvme0n1p3: UUID="4b6e5f78-222d-45d3-93fe-9f21b3fdf785" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="438388af-a853-466a-a51e-c4908268a08d"
# /dev/nvme0n1p1: UUID="E09E-D7DA" BLOCK_SIZE="512" TYPE="vfat" PARTUUID="10ca738b-4126-4a65-a39f-6adf051390c7"
# /dev/nvme0n1p4: UUID="c8c6dd1d-49d9-491f-8dab-2cf9c89a08cc" TYPE="swap" PARTUUID="8fbf9bb6-d95c-4007-aea1-8e2e05831c02"
# /dev/nvme0n1p2: UUID="E09E-D73B" BLOCK_SIZE="512" TYPE="vfat" PARTLABEL="recovery" PARTUUID="89981f8b-2ac6-429d-9a00-4f18b943986f"
# /dev/sdb: LABEL="Games" UUID="1c39032b-b81a-410d-9d7f-4a9ae60073d4" BLOCK_SIZE="4096" TYPE="ext4"
# /dev/sda2: UUID="57bfaaa1-652c-4c44-93b6-a54198e8fecc" BLOCK_SIZE="4096" TYPE="ext4" PARTLABEL="root" PARTUUID="671ecf12-59e9-4845-9938-c7964883474b"
# /dev/sda1: UUID="C53B-566A" BLOCK_SIZE="512" TYPE="vfat" PARTLABEL="EFI" PARTUUID="5c15cbc2-6d11-4339-b9f5-1589897cd369"

  fileSystems."/media/Games" = {
    device = "/dev/disk/by-uuid/1c39032b-b81a-410d-9d7f-4a9ae60073d4";
    fsType = "ext4";
    options = [ # If you don't have this options attribute, it'll default to "defaults" 
     # boot options for fstab. Search up fstab mount options you can use
      "defaults"
      "users" # Allows any user to mount and unmount
      "nofail" # Prevent system from failing if this drive doesn't mount
      "exec"
    ];
  };
}
