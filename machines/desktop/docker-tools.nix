# Docker + GPU containers for desktop. Rarely used, so they live in a
# boot-menu specialisation instead of the default system (the nvidia CDI
# generator alone added ~1.3s to boot). Pick "docker" in the limine menu,
# or switch live with:
#   sudo /run/current-system/specialisation/docker/bin/switch-to-configuration test
{ pkgs, ... }:
{
  specialisation.docker.configuration = {
    hardware.nvidia-container-toolkit.enable = true;
    virtualisation.docker = {
      enable = true;
    };
    users.users.david.extraGroups = [ "docker" ];
    # winboat runs Windows inside a docker container.
    environment.systemPackages = [ pkgs.winboat ];
  };
}
