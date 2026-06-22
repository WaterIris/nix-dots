{ pkgs, ... }:

{
  home.packages = [
    (pkgs.stdenv.mkDerivation {
      name = "personal_fonts";
      src = ./IosevkaCustom; 
      
      installPhase = ''
        mkdir -p $out/share/fonts/truetype
        cp -r . $out/share/fonts/truetype/
      '';
    })
  ];
    fonts.fontconfig.enable = true;
}
