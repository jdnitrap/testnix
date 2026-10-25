# testnix

Flake-based NixOS test project (GNOME Wayland + nixbook-style set-and-forget features).

## Usage

```bash
nix flake show
nixos-rebuild switch --flake .#test
```

Replace the placeholder UUIDs in `hardware-configuration.nix` with values from `nixos-generate-config` or your existing host.

## Features added from nixbook style

- zram swap (50%)
- Flatpak + Flathub remote (added on boot)
- Default Flatpak apps installed once: Chrome, LibreOffice, Zoom
- AppImage support
- Bluetooth
- Weekly auto-upgrade timer with desktop notifications (flake boot + Flatpak update)
- Powerwash desktop entry + script (confirm via zenity, wipe `/home/test`, reboot)
