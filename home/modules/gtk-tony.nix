{ config, pkgs, ... }:
{
    home.packages = with pkgs; [
        adwaita-icon-theme
        gnome-themes-extra
    ];
    gtk = {
        enable = true;
        theme = {
            name = "Adwaita-dark";
            package = pkgs.gnome-themes-extra;
        };
        iconTheme.name = "Adwaita";
        cursorTheme = {
            name = "Adwaita";
            package = pkgs.adwaita-icon-theme;
            size = 24;
        };
        gtk3.extraConfig = {
            gtk-application-prefer-dark-theme = 1;
        };

        gtk4.theme = null;
        gtk4.extraConfig = {
            gtk-application-prefer-dark-theme = 1;
        };
    };
    xdg.configFile."gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-theme-name=Adwaita-dark
            gtk-icon-theme-name=Adwaita
            gtk-cursor-theme-name=Adwaita
            gtk-cursor-theme-size=24
            gtk-application-prefer-dark-theme=1
            '';
    xdg.configFile."gtk-4.0/settings.ini".text = ''
        [Settings]
        gtk-theme-name=Adwaita-dark
            gtk-icon-theme-name=Adwaita
            gtk-cursor-theme-name=Adwaita
            gtk-cursor-theme-size=24
            gtk-application-prefer-dark-theme=1
            '';
    dconf.settings = {
        "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            gtk-theme = "Adwaita-dark";
        };
    };
    home.sessionVariables = {
        XCURSOR_THEME = "Adwaita";
        XCURSOR_SIZE = "24";
        GTK_THEME = "Adwaita:dark";
    };
}
