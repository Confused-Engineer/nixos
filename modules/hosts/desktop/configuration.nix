# desktop — main PC: AMD CPU, NVIDIA (GA104) GPU, COSMIC, gaming.
# The rest of this host is split across the other files in this directory,
# each adding to `flake.modules.nixos.desktop`:
#   hardware.nix     generated hardware config
#   data-mounts.nix  extra data disks + TrueNAS share
#   steam-os.nix     `steamos` boot-menu specialisation
#   docker.nix       `docker` boot-menu specialisation
#   home.nix         desktop-only home-manager additions for david
{ inputs, self, ... }:
{
  flake.nixosConfigurations.desktop = inputs.nixpkgs-unstable.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ self.modules.nixos.desktop ];
  };

  flake.modules.nixos.desktop =
    { pkgs, ... }:
    {
      imports = with self.modules.nixos; [
        nixpkgs
        binary-cache
        home-manager

        firefox
        flatpak
        lact
        steam
        controller-xbox
        gpu-nvidia
        boot
        de-cosmic
        gc
        settings-common
        settings-baseline
        yubikey
        system-api
      ];

      custom = {
        flatpak = {
          update = true;
          desiredFlatpaks = [
            "com.github.tchx84.Flatseal"
            "com.usebottles.bottles"
            "com.bambulab.BambuStudio"
            "org.freecad.FreeCAD"
            "com.plexamp.Plexamp"
          ];
        };

        firefox = {
          disableAccounts = false;
          privacy = "strict";
          homepage = "https://hp.a5f.org/";
        };

        de-cosmic = {
          strip.enable = true;
          nvidiaFix.hibernate = false;
        };

        boot = {
          fancy.enable = true;
          fancy.secureBoot = true;
          systemd = false;
        };
      };

      networking.hostName = "desktop";

      boot.kernelModules = [ "ntsync" ];
      boot.kernelPackages = pkgs.linuxPackages_zen;
      # Disable auto suspend to prevent the momentary Xbox controller connection drops during play.
      # boot.kernelParams = [ "btusb.enable_autosuspend=0" ];
      # Dont wait for network on boot, maybe boot faster?
      systemd.services.NetworkManager-wait-online.enable = false;

      programs.kdeconnect.enable = true;
      services.tailscale = {
        enable = true;

        # Declare the operator flag with your username
        extraUpFlags = [
          "--operator=david"
        ];
      };

      programs.gamemode = {
        enable = true;
        settings.general = {
          # gamemode negates this: games run at nice -10.
          renice = 10;
          inhibit_screensaver = 1;
          # Valid key for the governor switch (the old `[cpu] governor` key
          # was silently ignored). With amd-pstate-epp this also moves EPP to
          # "performance" while a game runs.
          desiredgov = "performance";
        };
      };
      # gamemode's polkit rule (governor/split-lock helpers) only authorises
      # members of this group; without it gamemoded logged "Not authorized".
      users.users.david.extraGroups = [ "gamemode" ];

      # Kernel module + user daemon for the Razer Basilisk V3 Pro / BlackWidow V3.
      # Re-enabled now that openrazer builds against kernels with module
      # signing (NixOS/nixpkgs#576293); the bare package's user unit failed
      # with 203/EXEC.
      hardware.openrazer = {
        enable = true;
        users = [ "david" ];
      };

      # Don't let the NVIDIA driver evict its shader cache (~/.cache/nvidia)
      # when it passes the size cap, so Heroic/non-Steam games don't
      # recompile shaders (stutter) after the cache rolls over. Trade-off: the
      # cache grows unbounded; delete ~/.cache/nvidia to reclaim space.
      environment.sessionVariables.__GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";

      # I/O schedulers: the zen kernel defaults to kyber (NVMe) / bfq (SATA).
      # For SSDs, none/mq-deadline have lower per-request overhead than bfq;
      # helps game/shader-cache loads off the SATA SSDs. Spinning disks (none
      # present today) keep bfq.
      services.udev.extraRules = ''
        ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
      '';

      environment.systemPackages = with pkgs; [
        heroic
        protonup-qt
        r2modman
        polychromatic
        gnome-system-monitor
        easyeffects
        streamcontroller
        vintagestory

        stable.pcsx2
        stable.rpcs3
        stable.dolphin-emu
      ];

      system.stateVersion = "26.05";
    };
}
