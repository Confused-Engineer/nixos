# hermes — Proxmox VM workstation for running the Hermes agent (Hermes
# Desktop), reached over RustDesk. XFCE on X11 with autologin to david, so
# RustDesk's system service always has a session to capture with nobody at
# the console (see de-xfce.nix for why not Wayland).
#
# Unstable, like the other home-manager hosts: home-manager and the
# hermes-agent HM module both track unstable.
#
# Disk layout comes from proxmox-vm (disko, /dev/sda). Install like
# server-template (see README.md "hermes"), substituting `#hermes`.
#
# Deliberately NOT using the shared `home-manager` aspect: that aspect also
# carries all of users/david.nix (discord, spotify, gimp, …). This VM gets a
# lean home with just the Hermes app and dev tools instead.
#
# Not in the repo (set once on the VM after install):
#   - david's password: `passwd` (the initialPassword below is a placeholder)
#   - RustDesk permanent password: RustDesk → Settings → Security
#   - Hermes provider/API keys: `hermes setup` (state in ~/.hermes)
{
  inputs,
  self,
  config,
  ...
}:
let
  inherit (config) sshKeys;
in
{
  flake.nixosConfigurations.hermes = inputs.nixpkgs-unstable.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ self.modules.nixos.hermes ];
  };

  flake.modules.nixos.hermes =
    { config, pkgs, ... }:
    let
      # rustdesk-flutter, not `rustdesk`: the latter links the unfree
      # libsciter, so Hydra never builds it and every update would be a
      # local source build. Same 1.5.x client, Flutter UI.
      rustdesk = pkgs.rustdesk-flutter;
    in
    {
      imports = with self.modules.nixos; [
        nixpkgs
        binary-cache
        inputs.home-manager.nixosModules.home-manager

        proxmox-vm
        firefox
        boot
        de-xfce
        gc
        settings-common
      ];

      custom = {
        # UEFI + systemd-boot — give the VM an OVMF/EFI disk in Proxmox.
        boot.systemd = true;

        de-xfce.autoLogin.user = "david";

        firefox = {
          privacy = "strict";
          homepage = "https://hp.a5f.org/";
        };
      };

      networking.hostName = "hermes";
      # DHCP; NetworkManager so XFCE's applet works.
      networking.networkmanager.enable = true;

      # Proxmox integration: guest agent for IP reporting/shutdown, SPICE
      # agent for clipboard and auto-resize in the Proxmox console.
      services.qemuGuest.enable = true;
      services.spice-vdagentd.enable = true;

      # Grow root to fill the virtual disk when it's enlarged in Proxmox, and
      # hand freed blocks back to thin storage — same as container-host.nix.
      boot.growPartition = true;
      fileSystems."/".autoResize = true;
      services.fstrim.enable = true;

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Same weekly schedule as settings-baseline (not imported: it also brings
      # printing, fwupd, gparted/sbctl — nothing a VM uses).
      system.autoUpgrade = {
        enable = true;
        flake = "github:Confused-Engineer/nixos#${config.networking.hostName}";
        flags = [
          "--refresh"
          "--no-write-lock-file"
        ];
        dates = "Sun 08:00";
        operation = "boot";
        randomizedDelaySec = "30min";
        allowReboot = false;
      };

      # Key-only SSH as david; root gets no SSH at all (sudo via wheel).
      services.openssh = {
        enable = true;
        settings.PasswordAuthentication = false;
        settings.KbdInteractiveAuthentication = false;
        settings.PermitRootLogin = "no";
        settings.AllowUsers = [ "david" ];
      };

      users.users.david = {
        isNormalUser = true;
        description = "david";
        # Provisioning password for sudo / the XFCE lock screen — change it
        # with `passwd` after install. (Not `password`: that's permanent.)
        initialPassword = "vmtest";
        extraGroups = [
          "networkmanager"
          "wheel"
          "audio"
        ];
        openssh.authorizedKeys.keys = sshKeys.david;
      };

      # ---------------------------------------------------------------------
      # RustDesk, as a root system service (upstream res/rustdesk.service).
      # The service is what makes access unattended: it spawns the capture
      # server inside david's X session, survives the GUI being closed, and
      # comes back after a reboot. Public ID/relay servers (client default),
      # so no inbound ports are needed; 21118/tcp is opened only so LAN
      # peers can use "direct IP access" instead of going through a relay.
      # ---------------------------------------------------------------------
      environment.systemPackages = [
        rustdesk
        pkgs.git
      ];

      systemd.services.rustdesk = {
        description = "RustDesk";
        wants = [ "network-online.target" ];
        after = [
          "network-online.target"
          "systemd-user-sessions.service"
          "display-manager.service"
        ];
        wantedBy = [ "multi-user.target" ];
        # --service shells out (ps, pkill, loginctl, awk, …) to find the
        # active X session and its XAUTHORITY.
        path = [
          rustdesk
          pkgs.procps
          pkgs.gawk
          pkgs.gnugrep
          pkgs.findutils
          pkgs.bash
          pkgs.coreutils
          "/run/wrappers"
          "/run/current-system/sw"
        ];
        environment = {
          PULSE_LATENCY_MSEC = "60";
          PIPEWIRE_LATENCY = "1024/48000";
        };
        serviceConfig = {
          Type = "simple";
          ExecStart = "${rustdesk}/bin/rustdesk --service";
          # Kills the --server/--tray children too (upstream's note: KillMode
          # alone doesn't).
          ExecStop = "${pkgs.procps}/bin/pkill -f \"rustdesk --\"";
          Restart = "always";
          RestartSec = 5;
          KillMode = "mixed";
          TimeoutStopSec = 30;
          LimitNOFILE = 100000;
        };
      };

      networking.firewall.allowedTCPPorts = [ 21118 ]; # RustDesk direct IP (LAN)

      # ---------------------------------------------------------------------
      # Lean home-manager for david (see header for why not the shared aspect).
      # ---------------------------------------------------------------------
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";

        users.david =
          { pkgs, ... }:
          {
            imports = [ inputs.hermes-agent.homeManagerModules.default ];

            # `hermes` CLI + Hermes Desktop (launcher entry). Gateway service
            # left off, same as desktop, until there's a secrets file for it.
            programs.hermes-agent = {
              enable = true;
              desktop.enable = true;
            };

            home.packages = with pkgs; [
              vscode
              nixd
              nixfmt
              inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
            ];

            home.username = "david";
            home.homeDirectory = "/home/david";
            home.stateVersion = "26.05";
          };
      };

      system.stateVersion = "26.05";
    };
}
