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
    ./containers.nix
    ./../../nixosModules
  ];

  custom.os.boot = {
    enable = true;
    systemd = true; # UEFI + systemd-boot — give the VM an OVMF/EFI disk in Proxmox
  };

  # Keep only the current generation + 1 previous — this box is backed up,
  # so anything further back is "restore from backup" territory anyway.
  custom.os.gc = {
    enable = true;
    generations = 2;
  };

  # Hardlink identical files across store paths — real disk savings on a
  # small VM disk, at the cost of a little extra CPU during GC.
  nix.settings.auto-optimise-store = true;
  # Belt-and-suspenders: trigger GC automatically the moment free space
  # drops below 1GB, not just on the weekly timer. Stops once 3GB is free.
  nix.settings.min-free = 1 * 1024 * 1024 * 1024;
  nix.settings.max-free = 3 * 1024 * 1024 * 1024;

  # Weekly `podman system prune`, so image/layer churn from updating
  # containers doesn't accumulate forever.
  virtualisation.podman.autoPrune.enable = true;

  # systemd-nspawn/machinectl containers — a separate subsystem from the
  # podman containers this host actually runs; nothing here uses it.
  boot.enableContainers = false;

  # Weekly TRIM so blocks freed by nix GC / podman prune actually get
  # returned to Proxmox's (thin-provisioned) storage, not just freed inside
  # the VM's own filesystem.
  services.fstrim.enable = true;

  # Unattended VM, nobody's rotating logs by hand — bound the journal.
  # SystemMaxUse caps persistent storage, RuntimeMaxUse caps the in-memory
  # journal used whenever persistent storage isn't set up.
  services.journald.extraConfig = ''
    SystemMaxUse=200M
    RuntimeMaxUse=100M
  '';

  networking.hostName = "music-assist";
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

  # Headless container host — skip building/installing man pages, the NixOS
  # manual, and option docs; nothing here ever reads them.
  documentation.enable = false;
  documentation.nixos.enable = false;
  documentation.man.enable = false;
  documentation.doc.enable = false;
  documentation.info.enable = false;

  # perl/rsync/strace ship on every NixOS system by default even though
  # nothing here uses them — switch-to-configuration-ng (Rust) doesn't need
  # perl like the old activation script did, so there's no hidden dependency
  # on it either. Explicitly documented as safe to drop for a minimal host.
  environment.defaultPackages = [ ];

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
  system.autoUpgrade = {
    enable = true;
    flake = "github:Confused-Engineer/nixos#${config.networking.hostName}";
    flags = [
      "--refresh"
      "--no-write-lock-file"
    ];
    dates = "*-*-01 04:00:00";
    operation = "boot";
    randomizedDelaySec = "5h";
    allowReboot = true;
  };

  system.stateVersion = "26.05";
}
