{ pkgs, ... }:
pkgs.stdenv.mkDerivation {
  name = "testnix-plymouth-theme";
  nativeBuildInputs = [ pkgs.imagemagick ];

  # Paths inside the .plymouth file are relative; NixOS plymouth module
  # places the theme under the store and sets Theme= by name.
  src = pkgs.writeTextDir "testnix.plymouth" ''
    [Plymouth Theme]
    Name=Testnix
    Description=Simple dark splash for testnix
    ModuleName=script

    [script]
    ImageDir=testnix
    ScriptFile=testnix.script
  '';

  installPhase = ''
    mkdir -p $out/share/plymouth/themes/testnix
    cp $src/testnix.plymouth $out/share/plymouth/themes/testnix/

    cat > $out/share/plymouth/themes/testnix/testnix.script <<'EOF'
# Simple dark splash with centered text and ring

Window.SetBackgroundTopColor(0.07, 0.07, 0.07);
Window.SetBackgroundBottomColor(0.07, 0.07, 0.07);

logo_image = Image("logo.png");
logo_sprite = Sprite(logo_image);
logo_sprite.SetX(Window.GetWidth() / 2 - logo_image.GetWidth() / 2);
logo_sprite.SetY(Window.GetHeight() / 2 - logo_image.GetHeight() / 2 - 40);

text_image = Image.Text("testnix", 1, 1, 1);
text_sprite = Sprite(text_image);
text_sprite.SetX(Window.GetWidth() / 2 - text_image.GetWidth() / 2);
text_sprite.SetY(Window.GetHeight() / 2 + 40);

fun refresh_callback () {
  logo_sprite.SetX(Window.GetWidth() / 2 - logo_image.GetWidth() / 2);
  logo_sprite.SetY(Window.GetHeight() / 2 - logo_image.GetHeight() / 2 - 40);
  text_sprite.SetX(Window.GetWidth() / 2 - text_image.GetWidth() / 2);
  text_sprite.SetY(Window.GetHeight() / 2 + 40);
}

Plymouth.SetRefreshFunction(refresh_callback);
EOF

    # White ring logo
    convert -size 96x96 xc:transparent \
      -fill white -draw "circle 48,48 48,8" \
      -fill "#121212" -draw "circle 48,48 48,20" \
      $out/share/plymouth/themes/testnix/logo.png
  '';
}
