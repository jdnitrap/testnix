# testnix

**A simple, durable, auto-updating NixOS system with a GNOME desktop — set it up once and stop worrying about it.**

Built as a test/lab system inspired by the set-and-forget goals of projects like [nixbook](https://github.com/mkellyxp/nixbook).

---

## What you get

- GNOME on Wayland with auto-login
- User `test` (password `t`)
- Automatic weekly updates (pulls this repo, rebuilds, updates Flatpaks)
- Powerwash option to wipe user data and reset to generation 1 if it exists
- Default apps via Flatpak: Chrome, LibreOffice, Zoom, Firefox, VLC, File Roller
- Custom Plymouth splash and matching GNOME wallpaper (dark background, white ring, “testnix” text)
- zram, Bluetooth, AppImage support

---

## Install

1. Boot a normal NixOS installer ISO on the target laptop.
2. Partition and format the disk (or use the installer's partitioning tool).
3. Clone the repo:
   ```bash
   sudo git clone https://github.com/jdnitrap/testnix.git /etc/nixos
   ```
4. Generate the real hardware config for *this* laptop (overwrites the placeholder):
   ```bash
   sudo nixos-generate-config --root /mnt
   ```
   This writes the correct disk UUIDs, kernel modules, and firmware into `/mnt/etc/nixos/hardware-configuration.nix`.
5. Install:
   ```bash
   sudo nixos-install --flake /etc/nixos#test --root /mnt
   ```
6. Reboot. It will auto-log in as `test`. Flatpak apps install in the background.

---

## Everyday use

Look under the System menu:

- **Update Now** — check for and install updates
- **List Generations** — see available system versions
- **Boot Default Generation** — switch to generation 1 if it exists
- **Powerwash** — wipe `/home/test` and reset to generation 1 if present

---

## Notes

- Password `t` is intentionally weak — this is a test system.
- Generation 1 is the intended fallback. The menu items check that it exists before switching.
- `hardware-configuration.nix` in the repo is a placeholder. `nixos-generate-config` on the target laptop replaces it with the real hardware for that machine.
- A btrfs snapshot-before-update experiment is commented in `nixbook-features.nix`. It is not active and only makes sense if root is btrfs.
- This is a work-in-progress test configuration, not a finished product.
