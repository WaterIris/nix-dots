{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    adwaita-icon-theme
    gnome-themes-extra
    bibata-cursors
  ];
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme.name = "Adwaita";
    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size = 24;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    # Tokyo Night colours on top of Adwaita-dark (same palette as waybar/rofi).
    # Adwaita hard-codes most colours, so the main widgets get explicit rules.
    gtk3.extraCss = ''
      @define-color tn_fg         #c0caf5;
      @define-color tn_fg_dim     #a9b1d6;
      @define-color tn_bg         #1a1b26;
      @define-color tn_surface    #16161e;
      @define-color tn_surface_alt #292e42;
      @define-color tn_subtle     #565f89;
      @define-color tn_blue       #7aa2f7;
      @define-color tn_blue_surface #1f2335;

      @define-color theme_fg_color tn_fg;
      @define-color theme_text_color tn_fg;
      @define-color theme_bg_color tn_bg;
      @define-color theme_base_color tn_bg;
      @define-color theme_selected_bg_color tn_blue;
      @define-color theme_selected_fg_color tn_surface;
      @define-color insensitive_fg_color tn_subtle;
      @define-color borders tn_surface_alt;

      window, .background, dialog, popover, menu {
        background-color: @tn_bg;
        color: @tn_fg;
      }

      .view, iconview, treeview, textview text, list, row {
        background-color: @tn_bg;
        color: @tn_fg;
      }

      headerbar, .titlebar, toolbar, .toolbar, statusbar,
      .sidebar, placessidebar, placessidebar list, placessidebar row {
        background-image: none;
        background-color: @tn_surface;
        border-color: @tn_surface_alt;
        box-shadow: none;
        color: @tn_fg_dim;
      }

      *:selected, .view:selected, iconview:selected, row:selected,
      treeview:selected, placessidebar row:selected {
        background-color: @tn_blue_surface;
        color: @tn_blue;
      }

      button {
        background-image: none;
        background-color: @tn_surface_alt;
        border-color: @tn_surface;
        box-shadow: none;
        color: @tn_fg;
      }

      button:hover {
        background-color: @tn_blue_surface;
        color: @tn_blue;
      }

      entry {
        background-color: @tn_surface;
        border-color: @tn_surface_alt;
        color: @tn_fg;
      }

      entry:focus {
        border-color: @tn_blue;
        box-shadow: inset 0 0 0 1px @tn_blue;
      }

      treeview header button {
        background-color: @tn_surface;
        color: @tn_subtle;
      }

      scrollbar slider {
        background-color: @tn_subtle;
      }
    '';
    gtk4.theme = null;
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };
  xdg.configFile."gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=Adwaita-dark
    gtk-icon-theme-name=Adwaita
    gtk-cursor-theme-name=Bibata-Modern-Ice
    gtk-cursor-theme-size=24
    gtk-application-prefer-dark-theme=1
  '';
  xdg.configFile."gtk-4.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=Adwaita-dark
    gtk-icon-theme-name=Adwaita
    gtk-cursor-theme-name=Bibata-Modern-Ice
    gtk-cursor-theme-size=24
    gtk-application-prefer-dark-theme=1
  '';
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Adwaita-dark";
      cursor-theme = "Bibata-Modern-Ice";
    };
  };
  home.sessionVariables = {
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
    GTK_THEME = "Adwaita:dark";
  };
}
