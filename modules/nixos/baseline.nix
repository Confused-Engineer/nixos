# Baseline for the interactive graphical hosts, desktop + laptop (was
# machines/baseline.nix). Kodi and attic define their own user / auto-upgrade
# schedule, so they include `common` but not this.
#
# Hosts that use this also include `common` (baseline used to import it; now
# the host composes both — see modules/hosts/*.nix).
{
  flake.modules.nixos.baseline =
    { config, pkgs, ... }:
    {
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

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

      networking.networkmanager.enable = true;

      services.printing.enable = true;

      users.users.david = {
        isNormalUser = true;
        description = "david";
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

      services.fwupd.enable = true;

      environment.systemPackages = with pkgs; [
        git
        gparted
        sbctl
        podman-compose
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
    };
}
