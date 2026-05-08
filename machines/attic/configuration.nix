{ config, pkgs, ... }:
let
  keys = import ./../../users/keys.nix;
in {
  imports = [
    ./hardware-configuration.nix
    ./../../nixosModules
  ];

  custom = {
    boot = {
      enable  = true;
      systemd = true;            # plain systemd-boot is fine for a server
    };

  };

  networking.hostName              = "attic";
  networking.networkmanager.enable = true;
  networking = {
    # Disable DHCP for the interface
    interfaces.enp3s0.useDHCP = false;
    
    # Set static IP address and prefix
    interfaces.ens18.ipv4.addresses = [ {
      address = "10.87.6.55";
      prefixLength = 24;
    } ];
    
    # Set default gateway
    defaultGateway = "10.87.6.1";
    
    # Set DNS servers
    nameservers = [ "10.87.6.10" ];
  };

  networking.firewall.allowedTCPPorts = [ 8080 ]; # Add your TCP ports here


  # `david` needs to be trusted by the daemon to push to the local store
  # during testing / manual `attic push` from this host. The cache itself
  # is reached over HTTPS regardless of this setting.
  nix.settings.trusted-users = [ "root" "david" ];

  time.timeZone      = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.openssh = {
    enable                           = true;
    settings.PasswordAuthentication  = false;
    settings.AllowUsers               = [ "david" "root" ];
    settings.PermitRootLogin          = "prohibit-password";
  };

  
  services.atticd = {
    enable = true;

    environmentFile = "/etc/atticd.env";

    settings = {
      listen = "[::]:8080";

      jwt = { };

      # Data chunking
      #
      # Warning: If you change any of the values here, it will be
      # difficult to reuse existing chunks for newly-uploaded NARs
      # since the cutpoints will be different. As a result, the
      # deduplication ratio will suffer for a while after the change.
      chunking = {
        # The minimum NAR size to trigger chunking
        #
        # If 0, chunking is disabled entirely for newly-uploaded NARs.
        # If 1, all NARs are chunked.
        nar-size-threshold = 64 * 1024; # 64 KiB

        # The preferred minimum size of a chunk, in bytes
        min-size = 16 * 1024; # 16 KiB

        # The preferred average size of a chunk, in bytes
        avg-size = 64 * 1024; # 64 KiB

        # The preferred maximum size of a chunk, in bytes
        max-size = 256 * 1024; # 256 KiB
      };

      compression = {
        type  = "zstd";
        level = 8;
      };

      # GC sweeps unreferenced chunks. Per-cache retention is set with
      # `attic cache configure <name> --retention-period <duration>`;
      # this is just the global default for caches that don't override.
      garbage-collection = {
        interval                 = "12 hours";
        default-retention-period = "6 months";
      };
    };
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

  # Auto-upgrade nightly. Server, no display, no one watching — switch in
  # place rather than waiting for a reboot.
  system.autoUpgrade = {
    enable             = true;
    flake              = "github:Confused-Engineer/nixos#${config.networking.hostName}";
    flags              = [ "--refresh" "--no-write-lock-file" ];
    dates              = "*-*-* 04:00:00";
    operation          = "switch";
    randomizedDelaySec = "30min";
    allowReboot        = false;
  };

  environment.systemPackages = with pkgs; [
    git
    attic-client       # `attic` CLI for managing the local server
  ];

  system.stateVersion = "25.05";
}
