# testnix

**A simple, durable, auto-updating NixOS system with a GNOME desktop — set it up once and stop worrying about it.**

Built as a test/lab system inspired by the set-and-forget goals of projects like [nixbook](https://github.com/mkellyxp/nixbook).

---

## What you get

- GNOME on Wayland with auto-login
- User `test` (password `t`)
- Automatic weekly updates (pulls this repo, rebuilds, updates Flatpaks)
- Powerwash option to wipe user data and reset to a known-good generation
- Default apps via Flatpak: Chrome, LibreOffice, Zoom, Firefox, VLC, File Roller
- Plymouth splash, zram, Bluetooth, AppImage support
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
- **Boot Default Generation** — go back to the protected fallback
- **Powerwash** — wipe `/home/test` and reset to generation 1

---

## Live installer ISO

```bash
nix build .#iso
```

ISO is in `result/iso/`. Test with `nix run .#vm`.

---

## Notes

- Password `t` is intentionally weak — this is a test system.
- Generation 1 is kept as the permanent safe fallback.
- Set the real disk path in `disko.nix` before installing on real hardware.
- This is a work-in-progress test configuration, not a finished product.
