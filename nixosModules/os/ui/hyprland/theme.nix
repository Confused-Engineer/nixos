{ pkgs, ... }: {

  

  dconf = {
    enable = true;
    settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };

  gtk = {
    enable = true;
    theme.name = "Adwaita-dark";
    
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;  # force dark in all GTK3 apps
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;  # force dark in all GTK4 apps
    };
  };
}