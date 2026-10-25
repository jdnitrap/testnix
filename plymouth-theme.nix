{ pkgs, ... }:
pkgs.stdenv.mkDerivation {
  name = "testnix-plymouth-theme";
  src = pkgs.writeTextDir "testnix.plymouth" ''
    [Plymouth Theme]
    Name=Testnix
    Description=Simple dark splash for testnix
    ModuleName=script

    [script]
    ImageDir=/usr/share/plymouth/themes/testnix
    ScriptFile=/usr/share/plymouth/themes/testnix/testnix.script
  '';

  installPhase = ''
    mkdir -p $out/share/plymouth/themes/testnix
    cp $src/testnix.plymouth $out/share/plymouth/themes/testnix/

    cat > $out/share/plymouth/themes/testnix/testnix.script <<'EOF'
# Simple dark splash with centered text and a subtle spinner

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
  # Keep logo and text centered on resize
  logo_sprite.SetX(Window.GetWidth() / 2 - logo_image.GetWidth() / 2);
  logo_sprite.SetY(Window.GetHeight() / 2 - logo_image.GetHeight() / 2 - 40);
  text_sprite.SetX(Window.GetWidth() / 2 - text_image.GetWidth() / 2);
  text_sprite.SetY(Window.GetHeight() / 2 + 40);
}

Plymouth.SetRefreshFunction(refresh_callback);
EOF

    # Simple white NixOS snowflake-style placeholder (1x1 will be replaced by real logo if present)
    # For a real logo, drop a PNG named logo.png next to this file and rebuild.
    ${pkgs.imagemagick}/bin/convert -size 96x96 xc:transparent \
      -fill white -draw "circle 48,48 48,8" \
      -fill "#1a1a1a" -draw "circle 48,48 48,20" \
      $out/share/plymouth/themes/testnix/logo.png || true
  '';
}
