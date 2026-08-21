{
  # oci-containers defaults to the podman backend (stateVersion >= 22.05),
  # which speaks the Docker API over its own socket rather than
  # /var/run/docker.sock. dockerSocket.enable symlinks the podman socket to
  # that path so Docker-oriented images (portainer, docker-socket-proxy)
  # keep working unmodified.
  virtualisation.podman.dockerSocket.enable = true;

  virtualisation.oci-containers.containers = {
    portainer = {
      autoStart = true;
      image = "portainer/portainer-ce:latest";
      ports = [
        "9443:9443"
        "8000:8000"
      ];
      volumes = [
        #"/var/run/docker.sock:/var/run/docker.sock"
        "portainer_data:/data"
      ];
    };
  };
}
