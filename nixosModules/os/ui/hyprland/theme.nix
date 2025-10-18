{ pkgs, ... }: {
  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";   # Libadwaita
        gtk-theme = "Adwaita-dark";     # GTK3
      };
    };
  };
}