({ lib, config, pkgs, ... }: {
  config = lib.mkIf (config.specialisation != {}) {
    services.sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;
    };

  };
})