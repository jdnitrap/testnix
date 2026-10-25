{ pkgs, ... }:
pkgs.runCommand "testnix-wallpaper" {
  nativeBuildInputs = [ pkgs.imagemagick pkgs.dejavu_fonts ];
} ''
  mkdir -p $out/share/backgrounds
  convert -size 1920x1080 xc:"#121212" \
    -fill white -draw "circle 960,480 960,380" \
    -fill "#121212" -draw "circle 960,480 960,420" \
    -fill white -font "${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans.ttf" -pointsize 48 -gravity center \
    -annotate +0+120 "testnix" \
    $out/share/backgrounds/testnix.jpg
''
