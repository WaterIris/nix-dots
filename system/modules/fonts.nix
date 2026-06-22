{ pkgs, ... }:
{
  fonts = {
    packages = [
      pkgs.nerd-fonts.mononoki
      pkgs.nerd-fonts.agave
      pkgs.nerd-fonts.iosevka
    ];
  };
}
