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
- Weekly auto-upgrade: clones https://github.com/jdnitrap/testnix.git to `/etc/nixos` (or pulls if already present), then runs `nixos-rebuild boot --flake /etc/nixos#test` + Flatpak update, with desktop notifications
- Powerwash desktop entry + script: switches back to protected default generation 1 (auto-fallback), wipes `/home/test`, reboots
- GC keeps generation 1 as the permanent fallback (weekly GC of older generations only)
