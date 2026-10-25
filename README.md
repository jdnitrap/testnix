# testnix

A flake-based NixOS system aimed at a simple, set-and-forget GNOME experience (inspired by ideas from nixbook).

- **Desktop**: GNOME on Wayland (GDM)
- **User**: `test` (password `t`, auto-login, wheel)
- **Channel**: nixpkgs `master`
- **Repo**: https://github.com/jdnitrap/testnix

## First-boot flow

1. Clone the repository to `/etc/nixos`:
   ```bash
   sudo git clone https://github.com/jdnitrap/testnix.git /etc/nixos
   ```
   (Or let the weekly auto-upgrade service do the clone on first run.)
2. Edit `hardware-configuration.nix` and replace the placeholder UUIDs with the real values from your machine:
   ```bash
   lsblk -f
   # or
   sudo nixos-generate-config
   ```
3. Build and switch:
   ```bash
   sudo nixos-rebuild switch --flake /etc/nixos#test
   ```
4. Reboot. The system will auto-log in as `test`.
5. Default Flatpak applications install in the background shortly after login.
6. From then on, the weekly timer keeps the system updated.

## Everyday use

Desktop menu entries (under System):

- **Update Now** — trigger the auto-upgrade immediately
- **List Generations** — show available system generations
- **Boot Default Generation** — switch back to the protected generation 1
- **Powerwash** — reset to generation 1, wipe `/home/test`, and reboot

## Features

- Plymouth boot splash and quiet boot
- Auto-login for the `test` user
- Default Adwaita dark wallpaper and reduced GNOME telemetry / software-center nags
- zram, Bluetooth, AppImage, thermald, power management
- Flatpak + Flathub with default apps: Chrome, LibreOffice, Zoom, Firefox, VLC, File Roller
- Weekly auto-upgrade that:
  - clones or pulls this repository to `/etc/nixos`
  - takes a btrfs snapshot of `/` when the root filesystem is btrfs
  - runs `nixos-rebuild boot --flake /etc/nixos#test`
  - updates Flatpaks
  - shows desktop notifications
- Protected generation 1 kept as the automatic fallback (weekly GC of older generations)
- Firewall enabled, SSH disabled

## Building the live installer ISO

A Calamares-based GNOME live installer is available:

```bash
nix build .#iso
```

The resulting ISO is in `result/iso/`. You can also test it in a VM with:

```bash
nix run .#vm
```

The live session auto-logs in as `nixos` and includes copies of the testnix configuration files in the store.

## Building from a clone

```bash
nix flake show
nixos-rebuild switch --flake .#test
```

## Notes

- The password `t` is intentionally weak for a pure test / lab system.
- Generation 1 is treated as the permanent safe fallback. The first successful boot after install becomes that generation.
- Hardware UUIDs in `hardware-configuration.nix` must be updated before the system will boot on real hardware.
