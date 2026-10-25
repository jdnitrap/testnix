# testnix

Flake-based NixOS test project (GNOME Wayland + nixbook-style set-and-forget features).

## Usage

```bash
nix flake show
nixos-rebuild switch --flake .#test
```

Replace the placeholder UUIDs in `hardware-configuration.nix` with values from `nixos-generate-config` or your existing host.

## Features added from nixbook style

- zram swap
- Flatpak + Flathub remote
- AppImage support
- Bluetooth
- Weekly auto-upgrade timer (flake boot + Flatpak update)
- `powerwash` script (confirm + wipe `/home/test` + reboot)
