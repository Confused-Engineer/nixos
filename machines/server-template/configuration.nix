# Proxmox VM template. Built as a generic NixOS-stable base image: disko
# owns the partition table on /dev/sda, cloud-init picks up per-clone
# network/hostname/SSH metadata from Proxmox, and the box auto-upgrades
# unattended since there's no one watching a template's console.
#
# After install, shut the VM down in Proxmox and convert it to a template;
# clones inherit this config until each is rebuilt onto its own flake host.
{ config, pkgs, ... }:
let
  keys = import ./../../users/keys.nix;
in
{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    ./../../nixosModules
  ];

  custom.os.boot = {
    enable = true;
    systemd = true; # UEFI + systemd-boot — give the VM an OVMF/EFI disk in Proxmox
  };

  # Keep only the current generation + 2 previous; anything past that is
  # "restore from backup" territory, not a rollback. custom.os.gc defaults
  # to 3 generations already — enabled here explicitly for clarity.
  custom.os.gc.enable = true;

  networking.hostName = "server-template";
  # cloud-init renders networkd config from Proxmox-supplied metadata per
  # clone, so networkd (not the scripted dhcpcd backend) has to own it.
  networking.useNetworkd = true;

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "david"
    ];
  };

  # Proxmox metrics/actions (shutdown, status, IP reporting) go through the
  # guest agent; cloud-init applies the per-clone metadata Proxmox injects.
  services.qemuGuest.enable = true;
  services.cloud-init = {
    enable = true;
    network.enable = true;
  };
  # Grow root to fill the disk on every boot, not just once at template
  # install time — covers a clone whose virtual disk got resized bigger in
  # Proxmox after the VM already existed. `growPartition` extends the GPT
  # partition itself (systemd service, runs unconditionally, no-op if
  # already full size); `autoResize` then grows the ext4 filesystem to
  # match via `x-systemd.growfs`. Both are needed — growing the partition
  # alone leaves the filesystem the old size.
  boot.growPartition = true;
  fileSystems."/".autoResize = true;

  virtualisation.docker.enable = true;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
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
        "docker"
      ];
      openssh.authorizedKeys.keys = keys.david;
    };
    root.openssh.authorizedKeys.keys = keys.david;
  };

  # Monthly, unattended, restart if the new generation needs it — a template
  # clone has no one around to babysit a switch.
  #system.autoUpgrade = {
  #  enable = true;
  #  flake = "github:Confused-Engineer/nixos#${config.networking.hostName}";
  #  flags = [
  #    "--refresh"
  #    "--no-write-lock-file"
  #  ];
  #  dates = "*-*-01 04:00:00";
  #  operation = "boot";
  #  randomizedDelaySec = "5h";
  #  allowReboot = true;
  #};

  environment.systemPackages = with pkgs; [
    git
  ];

  system.stateVersion = "26.05";
}
