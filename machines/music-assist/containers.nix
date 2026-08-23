{
  # NixOS's firewall defaults to dropping anything not explicitly allowed —
  # container port-publishing/`--network=host` doesn't open a hole in it on
  # its own. Music Assistant's confirmed ports (8095 web UI, 8097
  # streamserver, 8927 Sendspin) all fall in this range; opened as one range
  # rather than an exact list so new player providers/ports don't need a
  # repo change to reach players on the LAN.
  networking.firewall.allowedTCPPortRanges = [
    {
      from = 3000;
      to = 10000;
    }
  ];
  networking.firewall.allowedUDPPortRanges = [
    {
      from = 3000;
      to = 10000;
    }
  ];

  virtualisation.oci-containers.containers = {
    # Read-only view of the podman socket for homepage's Docker widget:
    # POST=0 keeps it read-only, CONTAINERS/SERVICES/TASKS gate which
    # endpoints are exposed. https://github.com/Tecnativa/docker-socket-proxy
    dockerproxy = {
      autoStart = true;
      image = "ghcr.io/tecnativa/docker-socket-proxy:latest";
      environment = {
        CONTAINERS = "1";
        SERVICES = "1";
        TASKS = "1";
        POST = "0";
      };
      ports = [
        "2375:2375"
      ];
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock:ro"
      ];
    };

    music-assistant-server = {
      autoStart = true;
      image = "ghcr.io/music-assistant/server:latest";
      # SYS_ADMIN + DAC_READ_SEARCH and an unconfined apparmor profile are
      # needed for MA to mount SMB shares from inside the container.
      capabilities = {
        SYS_ADMIN = true;
        DAC_READ_SEARCH = true;
      };
      volumes = [
        "music-assistant-data:/data/"
      ];
      environment = {
        LOG_LEVEL = "info";
      };
      labels = {
        "homepage.instance.private.group" = "Media";
        "homepage.instance.private.name" = "Music Assistant";
        "homepage.instance.private.icon" = "si-musicbrainz-#000000";
        "homepage.instance.private.href" = "http://music-assist.internal:8095";
        "homepage.instance.private.description" = "Music Assistant Server";
        "homepage.instance.private.weight" = "4";
      };
      # network_mode: host is required for MA's discovery/streaming to work
      # correctly, so ports aren't published individually; --dns and
      # --security-opt cover the compose file's remaining top-level keys
      # that oci-containers has no dedicated option for.
      extraOptions = [
        "--network=host"
        "--dns=10.87.6.10"
        "--security-opt=apparmor=unconfined"
      ];
    };
  };
}
