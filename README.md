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
- Declarative disk layout with [disko](https://github.com/nix-community/disko)

---

## Install

1. Boot a NixOS installer (or build the live ISO below).
2. Clone the repo:
   ```bash
   sudo git clone https://github.com/jdnitrap/testnix.git /etc/nixos
   ```
3. Edit `disko.nix` and set your real disk (replace `/dev/disk/by-id/CHANGE-ME`).
4. Run:
   ```bash
   sudo nix run github:nix-community/disko -- --mode disko /etc/nixos/disko.nix
   sudo nixos-install --flake /etc/nixos#test --root /mnt
   ```
5. Reboot. It will auto-log in as `test`. Flatpak apps install in the background.

---

## Everyday use

Look under the System menu:

- **Update Now** — check for and install updates
- **List Generations** — see available system versions
- **Boot Default Generation** — switch to generation 1 if it exists
- **Powerwash** — wipe `/home/test` and reset to generation 1 if present

---

## Live installer ISO

```bash
nix build .#iso
```

ISO is in `result/iso/`. Test with `nix run .#vm`.

The live ISO is stock GNOME + Calamares. The testnix config files are copied into the ISO for reference; they are not applied automatically.

---

## Notes

- Password `t` is intentionally weak — this is a test system.
- Generation 1 is the intended fallback. The menu items check that it exists before switching.
- Set the real disk path in `disko.nix` before installing on real hardware.
- `hardware-configuration.nix` is unused when disko is active and contains placeholders only.
- A btrfs snapshot-before-update experiment is commented in `nixbook-features.nix`. It is not active and only makes sense if root is btrfs.
- This is a work-in-progress test configuration, not a finished product.
