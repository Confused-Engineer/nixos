{ lib, config, pkgs, ... }:
with lib;
let
  # We point directly to 'gnugrep' instead of 'grep'
  grep = pkgs.gnugrep;
  # 1. Declare the Flatpaks you *want* on your system
#  desiredFlatpaks = [
#  #  "org.onlyoffice.desktopeditors"
#  ];

  cfg = config.services.custom.flatpaks;

in {

  options.services.custom.flatpaks = {

    enable = mkEnableOption "Enable Flatpacks";

    desiredFlatpaks = pkgs.lib.mkOption {
      description = "list of flatpaks";
      type = lib.types.listOf types.str;
    };

    update = mkEnableOption "Updates flatpaks on rebuild";

  };

  config = mkIf cfg.enable {
    
    services.flatpak.enable = true;
    environment.systemPackages = [ pkgs.gnugrep ];

    system.userActivationScripts.flatpakManagement = {
      text = ''
        # 2. Ensure the Flathub repo is added
        ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub \
          https://flathub.org/repo/flathub.flatpakrepo

        # 3. Get currently installed Flatpaks
        installedFlatpaks=$(${pkgs.flatpak}/bin/flatpak list --app --columns=application)

        # 4. Remove any Flatpaks that are NOT in the desired list
        for installed in $installedFlatpaks; do
          if ! echo ${toString cfg.desiredFlatpaks} | ${grep}/bin/grep -q $installed; then
            echo "Removing $installed because it's not in the desiredFlatpaks list."
            ${pkgs.flatpak}/bin/flatpak uninstall -y --noninteractive $installed
          fi
        done

        # 5. Install or re-install the Flatpaks you DO want
        for app in ${toString cfg.desiredFlatpaks}; do
          echo "Ensuring $app is installed."
          ${pkgs.flatpak}/bin/flatpak install -y flathub $app
        done

        # 6. Remove unused Flatpaks
        ${pkgs.flatpak}/bin/flatpak uninstall --unused -y
      '';
    };

    system.userActivationScripts.flatpakUpdate = mkIf cfg.update {
      text = ''
        # 7. Update all installed Flatpaks
        ${pkgs.flatpak}/bin/flatpak update -y
      '';
    };
  };

}