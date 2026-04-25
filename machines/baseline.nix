{ config, lib, pkgs, ... }:
{
  nix.settings.experimental-features = ["nix-command" "flakes"];


  system.autoUpgrade = {
    enable = true;
    flake = "github:Confused-Engineer/nixos#${config.networking.hostName}";
    flags = [ "--refresh" "--no-write-lock-file" ];
    dates = "Sun 08:00";
    operation = "switch";
    randomizedDelaySec = "30min";
    allowReboot = false;
  };


  networking.networkmanager.enable = true;
  time.timeZone = "America/New_York";
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
  services.printing.enable = true;
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

  users.users.david = {
    isNormalUser = true;
    initialPassword = "vmtest";
    description = "david";
    extraGroups = [ "networkmanager" "wheel" "audio" "openrazer" "dialout" "docker"];
    packages = with pkgs; [
    #  thunderbird
    ];
  };
  
  services.fwupd.enable = true;
  nixpkgs.config.allowUnfree = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    fira-sans
    fira-code
    nerd-fonts.fira-code
    font-awesome
    material-design-icons
    corefonts
  ];

}
