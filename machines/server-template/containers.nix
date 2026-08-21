{
  # oci-containers defaults to the podman backend (stateVersion >= 22.05),
  # which speaks the Docker API over its own socket rather than
  # /var/run/docker.sock. dockerSocket.enable symlinks the podman socket to
  # that path so Docker-oriented images (like docker-socket-proxy) keep
  # working unmodified. See machines/controller/containers.nix.
  virtualisation.podman.dockerSocket.enable = true;

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
