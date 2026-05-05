{ config, lib, pkgs, ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.autoUpgrade = {
    enable             = true;
    flake              = "github:Confused-Engineer/nixos#${config.networking.hostName}";
    flags              = [ "--refresh" "--no-write-lock-file" ];
    dates              = "Sun 08:00";
    operation          = "boot";
    randomizedDelaySec = "30min";
    allowReboot        = false;
  };

  networking.networkmanager.enable = true;
  time.timeZone                    = "America/New_York";

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

  services.printing.enable  = true;
  services.pulseaudio.enable = false;
  security.rtkit.enable      = true;

  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
  };

  users.users.david = {
    isNormalUser = true;
    description  = "david";
    # Provisioning password — should be changed on first login. Set via
    # `passwd` after install. (Not `password` because that's permanent.)
    initialPassword = "vmtest";
    extraGroups = [
      "networkmanager"
      "wheel"
      "audio"
      "openrazer"
      "dialout"
      "docker"
      "podman"
    ];
  };

  virtualisation = {
    containers.enable = true;
    podman = {
      enable        = true;
      dockerCompat  = true;
      # Required for containers under podman-compose to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  services.fwupd.enable = true;

  environment.systemPackages = with pkgs; [
    git
    gparted
    sbctl
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    nerd-fonts.fira-code
    fira-sans
    fira-code
    font-awesome
    material-design-icons
    corefonts
  ];
}
