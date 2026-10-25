# testnix

Flake-based NixOS test project (GNOME Wayland + nixbook-style set-and-forget features).

## First-boot flow

1. Clone the repo to `/etc/nixos` (or let the auto-upgrade service do it).
2. Replace the placeholder UUIDs in `hardware-configuration.nix` with real values from `lsblk -f` or `nixos-generate-config`.
3. Run `nixos-rebuild switch --flake /etc/nixos#test`.
4. Reboot. The system auto-logs in as user `test` (password `t`).
5. Default Flatpak apps install in the background and appear shortly after login.
6. Future weekly updates pull the repo, optionally snapshot (btrfs), rebuild, and update Flatpaks.

## Usage

```bash
nix flake show
nixos-rebuild switch --flake .#test
```

## Features

- GNOME Wayland + auto-login for user `test`
- Plymouth boot splash + quiet boot
- Default wallpaper (Adwaita dark) and reduced telemetry/nags
- zram, Bluetooth, AppImage, thermald, power management
- Flatpak + Flathub with defaults: Chrome, LibreOffice, Zoom, Firefox, VLC, File Roller
- Weekly auto-upgrade that clones/pulls the repo, takes a btrfs snapshot if applicable, then rebuilds + Flatpak update
- Desktop entries: Update Now, List Generations, Boot Default Generation, Powerwash
- Powerwash resets to protected generation 1 + wipes `/home/test`
