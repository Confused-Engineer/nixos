# XFCE on X11, via LightDM. Like every de-* aspect, keeps an `enable`
# option (default on) so specialisations can switch it off — see
# de-cosmic.nix. X11 rather than a Wayland session on purpose: remote
# desktop tools (RustDesk) can only do unattended capture/input on X11 —
# on Wayland every connection needs a portal prompt approved on the
# machine itself.
{
  flake.modules.nixos.de-xfce =
    { lib, config, ... }:
    let
      cfg = config.custom.de-xfce;
    in
    {
      options.custom.de-xfce = {
        enable = lib.mkEnableOption "XFCE desktop (X11, LightDM)" // {
          default = true;
        };
        autoLogin.user = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "david";
          description = ''
            Log this user straight into XFCE at boot. Meant for headless VMs
            reached over remote desktop, where there's no one at the console
            to get past the greeter. null = show the LightDM greeter.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        services.xserver = {
          enable = true;
          desktopManager.xfce.enable = true;
          displayManager.lightdm.enable = true;
        };
        services.displayManager = {
          defaultSession = "xfce";
          autoLogin = lib.mkIf (cfg.autoLogin.user != null) {
            enable = true;
            inherit (cfg.autoLogin) user;
          };
        };
      };
    };
}
