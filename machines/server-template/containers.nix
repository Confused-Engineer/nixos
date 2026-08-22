{
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
  };
}
