{
  virtualisation.oci-containers.containers = {
    portainer = {
      autoStart = true;
      image = "portainer/portainer-ce:latest";
      ports = [
        "9443:9443"
        "8000:8000"
      ];
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "portainer_data:/data"
      ];
    };
  };
}
