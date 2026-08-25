{
  # filebrowser's own port isn't opened by publishing it — NixOS's firewall
  # defaults to dropping anything not explicitly allowed.
  networking.firewall.allowedTCPPorts = [ 8080 ];

  # filebrowser's process runs as a baked-in UID/GID 1000 (not root) inside
  # the container. If these host paths don't exist yet, podman auto-creates
  # them as root:root on first bind-mount, which that UID can't write to —
  # pre-create them owned by 1000:1000 so settings.json/the sqlite DB
  # actually persist. (/srv/terraria itself is the pre-existing world-data
  # directory, not managed here — if filebrowser can't save edits to files
  # under it, its ownership/permissions need checking on the host
  # separately.)
  systemd.tmpfiles.rules = [
    "d /srv/terraria-filebrowser 0755 root root -"
    "d /srv/terraria-filebrowser/config 0755 1000 1000 -"
    "d /srv/terraria-filebrowser/database 0755 1000 1000 -"
    "d /srv/terraria/serverplugins 0755 1000 1000 -"
    "d /srv/terraria/01 0755 1000 1000 -"
    "d /srv/terraria/logs 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers = {
    terraria = {
      autoStart = true;
      image = "ryshe/terraria:latest";
      # The image has no USER directive (runs as root by default). Matching
      # filebrowser's UID/GID keeps both containers' writes to /srv/terraria
      # under one consistent ownership. /tshock/ServerPlugins and
      # /tshock/logs are otherwise anonymous podman volumes that inherit
      # root ownership from the image, so bootstrap.sh's first-run plugin
      # copy and TShock's log writes would fail as UID 1000 without also
      # bind-mounting them here.
      user = "1000:1000";
      # TShock.Server is a self-contained .NET single-file bundle — it needs
      # a writable directory to extract itself into at startup, and its
      # default target is /tshock (the image's WorkingDir), which is
      # root-owned from the image build and not writable by UID 1000.
      # Redirect extraction to /tmp, which is writable regardless of UID.
      environment = {
        DOTNET_BUNDLE_EXTRACT_BASE_DIR = "/tmp";
      };
      ports = [
        "7777:7777" # Terraria server
        "7878:7878" # TShock REST API
      ];
      volumes = [
        "/srv/terraria/01:/root/.local/share/Terraria/Worlds"
        "/srv/terraria/serverplugins:/tshock/ServerPlugins"
        "/srv/terraria/logs:/tshock/logs"
      ];
      cmd = [
        "-world"
        "/root/.local/share/Terraria/Worlds/world.wld"
        "-autocreate"
        "3"
        "-worldname"
        "Terraria w da guys"
        "-maxplayers"
        "16"
        "-difficulty"
        "2"
        "-pass"
        "a"
        "-noupnp"
      ];
      # stdin_open/tty from the compose file — TShock reads commands from stdin.
      extraOptions = [
        "--interactive"
        "--tty"
      ];
    };

    # Web UI at :8080 for browsing/editing world files under /srv/terraria
    # without needing to shell into the host. The image keeps its admin
    # user/password in /database/filebrowser.db (referenced by
    # /config/settings.json) — without persisting those two paths too, the
    # admin account resets to the filebrowser/filebrowser default every time
    # the container gets recreated (image update, podman autoPrune, reboot).
    filebrowser = {
      autoStart = true;
      image = "filebrowser/filebrowser:latest";
      # The image's baked-in USER is non-root, and its default settings.json
      # listens on :80 — a privileged port that UID can't bind. Override to
      # 8080 (the filebrowser binary's own --port default) via env var,
      # which per its documented precedence (flags > env vars > config file)
      # wins over the port baked into settings.json.
      environment = {
        FB_PORT = "8080";
      };
      ports = [
        "8080:8080"
      ];
      volumes = [
        "/srv/terraria:/srv"
        "/srv/terraria-filebrowser/config:/config"
        "/srv/terraria-filebrowser/database:/database"
      ];
    };
  };
}
