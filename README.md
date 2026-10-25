# testnix

Flake-based NixOS test project (GNOME Wayland + nixbook-style set-and-forget features).

## Usage

```bash
nix flake show
nixos-rebuild switch --flake .#test
```

Replace the placeholder UUIDs in `hardware-configuration.nix` with values from `nixos-generate-config` or your existing host.

## Features

- GNOME Wayland + auto-login for user `test`
- Plymouth boot splash
- zram, Bluetooth, AppImage, thermald, power management
- Flatpak + Flathub with defaults: Chrome, LibreOffice, Zoom, Firefox, VLC, File Roller
- GNOME polish (favorites, reduced telemetry/nags)
- Weekly auto-upgrade that clones/pulls the repo then rebuilds + Flatpak update
- Desktop entries: Update Now, List Generations, Powerwash
- Powerwash resets to protected generation 1 + wipes `/home/test`
