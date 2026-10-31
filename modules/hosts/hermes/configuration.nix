# hermes — headless Proxmox VM for running the Hermes agent CLI, reached
# over SSH. No desktop session, display manager or remote-desktop server:
# everything Hermes needs (the `hermes` CLI/TUI, the messaging gateway,
# signal-cli for the Signal adapter) runs fine without a display.
#
# Unstable, like the other home-manager hosts: home-manager and the
# hermes-agent HM module both track unstable.
#
# Disk layout comes from proxmox-vm (disko, /dev/sda). Install like
# server-template (see README.md "hermes"), substituting `#hermes`.
#
# Deliberately NOT using the shared `home-manager` aspect: that aspect also
# carries all of users/david.nix (discord, spotify, gimp, …). This VM gets a
# lean home with just Hermes, signal-cli and dev tools instead.
#
# Not settings-common either: it brings PipeWire/xkb, which a headless VM
# doesn't use. Locale and timezone are set inline below instead.
#
# Not in the repo (set once on the VM after install):
#   - david's password: `passwd` (the initialPassword below is a placeholder)
#   - Hermes provider/API keys: `hermes setup` (state in ~/.hermes)
#   - Signal: `signal-cli link -n hermes` (linked device; state in
#     ~/.local/share/signal-cli), then `hermes gateway setup` → Signal
#   - GitHub: `gh auth login` (fine-grained token, this repo only)
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
    {
      imports = with self.modules.nixos; [
        nixpkgs
        binary-cache
        inputs.home-manager.nixosModules.home-manager

        proxmox-vm
        boot
        gc
      ];

      # UEFI + systemd-boot — give the VM an OVMF/EFI disk in Proxmox.
      custom.boot.systemd = true;

      networking.hostName = "hermes";
      # Plain DHCP (NixOS default networking.useDHCP); no NetworkManager
      # without a desktop applet to drive it.

      time.timeZone = "America/New_York";
      i18n.defaultLocale = "en_US.UTF-8";

      # Proxmox guest agent for IP reporting / clean shutdown.
      services.qemuGuest.enable = true;

      # Grow root to fill the virtual disk when it's enlarged in Proxmox, and
      # hand freed blocks back to thin storage — same as container-host.nix.
      boot.growPartition = true;
      fileSystems."/".autoResize = true;
      services.fstrim.enable = true;

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
      # Let david push unsigned, desktop-built paths (`nixos-rebuild
      # --target-host david@hermes.internal`); same as kodi. Not a real
      # privilege bump: david already has full sudo via wheel.
      nix.settings.trusted-users = [
        "root"
        "david"
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
        # Provisioning password for sudo / the Proxmox console — change it
        # with `passwd` after install. (Not `password`: that's permanent.)
        initialPassword = "vmtest";
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = sshKeys.david;
        # Start david's user services (signal-cli) at boot and keep them
        # running with nobody logged in; without this the user manager only
        # runs while an SSH session is open.
        linger = true;
      };

      environment.systemPackages = [ pkgs.git ];

      # ---------------------------------------------------------------------
      # Lean home-manager for david (see header for why not the shared aspect).
      # ---------------------------------------------------------------------
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";

        users.david =
          {
            lib,
            pkgs,
            osConfig,
            ...
          }:
          {
            imports = [ inputs.hermes-agent.homeManagerModules.default ];

            # `hermes` CLI only (no Hermes Desktop: nothing to display it on).
            programs.hermes-agent.enable = true;

            # Anthropic via a pay-per-token API key (added on the VM with
            # `hermes auth add anthropic --type api-key`; state in ~/.hermes).
            # The Claude Pro subscription can't back Hermes: its OAuth path
            # needs Max + extra-usage credits. Only these keys are pinned in
            # ~/.hermes/config.yaml (deep merge on activation); everything else
            # stays editable at runtime, but a `/model --global` change is reset
            # on the next switch, so change the model here.
            services.hermes-agent = {
              enable = true;
              settings = {
                model.provider = "anthropic";
                model.default = "claude-sonnet-5";
                # Don't borrow Claude Code's Pro login (~/.claude): Hermes
                # can't bill a Pro plan, and claude itself keeps using it.
                auth.adopt_external_logins = false;
              };

              # Messaging gateway (Signal) as a user service; it also runs the
              # cron scheduler (daily CI check). Needs SIGNAL_* in ~/.hermes/.env.
              gateway.enable = true;

              # The gateway unit's PATH is only hermes, bash, coreutils and git
              # plus these (home.packages does NOT reach it); the module also
              # adds them to home.packages for interactive use. Enough to read
              # GitHub Actions failures, fix the flake and build-check a host.
              extraPackages = with pkgs; [
                gh # runs, failed-job logs, PRs (auth: `gh auth login`)
                osConfig.nix.package # nix build/eval/flake from the service
                nixfmt
                nixd
                gnugrep
                gnused
                gawk
                findutils
                diffutils
                ripgrep
                jq
              ];
            };

            # signal-cli daemon for the Hermes Signal adapter (replaces the
            # hand-made ~/.config/systemd/user/signal-cli.service). The account
            # number comes from SIGNAL_ACCOUNT in ~/.hermes/.env, the same file
            # the gateway reads, so it stays out of the repo; systemd expands
            # ${SIGNAL_ACCOUNT} from EnvironmentFile. --receive-mode
            # on-connection: only fetch messages while Hermes is connected, so
            # nothing is consumed (and lost) while the gateway is down.
            # No network-online.target: that is a system target the user
            # manager can't see; Restart covers a slow network at boot.
            systemd.user.services.signal-cli = {
              Unit.Description = "signal-cli JSON-RPC/HTTP daemon for Hermes";
              Service = {
                EnvironmentFile = "%h/.hermes/.env";
                ExecStart = "${lib.getExe pkgs.signal-cli} -a \${SIGNAL_ACCOUNT} daemon --http 127.0.0.1:8080 --receive-mode on-connection";
                Restart = "on-failure";
                RestartSec = 10;
              };
              Install.WantedBy = [ "default.target" ];
            };

            # Hermes talks to the signal-cli daemon over HTTP, so start it first
            # (the adapter also reconnects on its own if signal-cli restarts).
            systemd.user.services.hermes-agent.Unit = {
              Wants = [ "signal-cli.service" ];
              After = [ "signal-cli.service" ];
            };

            home.packages = with pkgs; [
              # Signal adapter backend: Hermes talks to
              # `signal-cli daemon --http 127.0.0.1:8080`.
              signal-cli
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
