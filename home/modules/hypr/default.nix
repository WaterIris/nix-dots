{ ... }:
{
  home.file.".config/hypr/hyprland.conf" = {
    source = ./hyprland.conf;
  };
  home.file.".config/hypr/hyprpaper.conf" = {
    source = ./hyprpaper.conf;
  };
  home.file.".config/hypr/hyprlock.conf" = {
    source = ./hyprlock.conf;
  };

  home.file.".config/hypr/hypridle.conf" = {
    source = ./hypridle.conf;
  };

  home.file.".config/hypr/source" = {
    source = ./source;
    recursive = true;
  };

  home.file.".config/hypr/assets" = {
    source = ./assets;
    recursive = true;
  };

}
