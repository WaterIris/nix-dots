{ ... }:
{
  home.file.".config/kitty/kitty.conf" = {
    source = ./kitty.conf;
  };

  home.file.".config/kitty/colors.conf" = {
    source = ./colors.conf;
  };

}
