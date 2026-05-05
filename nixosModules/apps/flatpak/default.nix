{ lib, config, pkgs, ... }:
let
  cfg = config.custom.apps.flatpaks;
in {
  options.custom.apps.flatpaks = {
    enable = lib.mkEnableOption "Flatpak with declarative app management";

    desiredFlatpaks = lib.mkOption {
      type        = lib.types.listOf lib.types.str;
      default     = [ ];
      description = "Flatpak app IDs to keep installed. Anything else managed by this hook will be removed.";
      example     = [ "com.github.tchx84.Flatseal" ];
    };

    update = lib.mkEnableOption "auto-update flatpaks on activation";
  };

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;

    # System-side install/remove runs once at activation as root, not per-user.
    # The per-user activation hook used previously fired on every login and
    # could remove flatpaks belonging to other users.
    system.activationScripts.flatpakManagement = {
      text = ''
        # Add Flathub if it's not already configured (system-wide).
        ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists --system flathub \
          https://flathub.org/repo/flathub.flatpakrepo

        # Compute desired set as newline-separated for safe exact-match comparison.
        desired=$(printf '%s\n' ${lib.escapeShellArgs cfg.desiredFlatpaks})

        # Remove anything system-installed that isn't desired (exact match, no
        # substring, no regex — the previous `grep -q` matched org.gnome.FooBar
        # against org.gnome.Foo and similar near-misses).
        installed=$(${pkgs.flatpak}/bin/flatpak list --system --app --columns=application)
        for app in $installed; do
          if ! printf '%s\n' "$desired" | ${pkgs.gnugrep}/bin/grep -Fxq "$app"; then
            echo "flatpakManagement: removing $app"
            ${pkgs.flatpak}/bin/flatpak uninstall --system -y --noninteractive "$app" || true
          fi
        done

        # Install anything desired but missing.
        for app in ${lib.escapeShellArgs cfg.desiredFlatpaks}; do
          if ! printf '%s\n' "$installed" | ${pkgs.gnugrep}/bin/grep -Fxq "$app"; then
            echo "flatpakManagement: installing $app"
            ${pkgs.flatpak}/bin/flatpak install --system -y flathub "$app" || true
          fi
        done

        # Tidy up unused runtimes.
        ${pkgs.flatpak}/bin/flatpak uninstall --system --unused -y || true
      '';
    };

    # Updates touch user data, so they belong in user activation, gated.
    system.userActivationScripts.flatpakUpdate = lib.mkIf cfg.update {
      text = ''
        ${pkgs.flatpak}/bin/flatpak update --user -y || true
        ${pkgs.flatpak}/bin/flatpak update --system -y || true
      '';
    };
  };
}
