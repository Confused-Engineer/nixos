{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.custom.os.yubikey;
in
{
  options.custom.os.yubikey = {
    enable = lib.mkEnableOption "YubiKey U2F for login/sudo, with password always kept as a fallback";

    pamServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "login" # virtual console login
        "sudo"
        "cosmic-greeter" # COSMIC's graphical login/lock screen
        "polkit-1" # GUI privilege prompts (pkexec, cosmic-settings, ...)
      ];
      description = ''
        PAM services that accept the YubiKey as an auth factor, on top of
        the normal password. Each entry gets `u2f.enable = true`, and
        `security.pam.u2f`'s "control" is left at its default of
        "sufficient": touching the key succeeds immediately, but a missing,
        unregistered, or failed key always falls through to the regular
        password prompt. It is deliberately never set to "required" — there
        is no scenario where losing the key locks you out.

        Add more service names here (e.g. a screen locker) if something
        else should accept the key too.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # ykman (device inspection/management) plus the udev rules it needs to
    # talk to the key without root.
    programs.yubikey-manager.enable = true;

    # pamu2fcfg — used once to register a key into u2f_keys.
    environment.systemPackages = [ pkgs.pam_u2f ];

    security.pam.u2f.settings = {
      cue = true; # print "Please touch the device" while it waits
    };

    security.pam.services = lib.genAttrs cfg.pamServices (_: {
      u2f.enable = true;
    });
  };
}
