# testnix

A flake-based NixOS system aimed at a simple, set-and-forget GNOME experience (inspired by ideas from nixbook).

- **Desktop**: GNOME on Wayland (GDM)
- **User**: `test` (password `t`, auto-login, wheel)
- **Channel**: nixpkgs `master`
- **Repo**: https://github.com/jdnitrap/testnix

## First-boot flow (with disko)

1. Clone the repository to `/etc/nixos`:
   ```bash
   sudo git clone https://github.com/jdnitrap/testnix.git /etc/nixos
   ```
2. Edit `disko.nix` and set the real disk device (e.g. `/dev/nvme0n1` or `/dev/sda`).
3. From the installer environment, run disko to partition/format/mount, then install:
   ```bash
   sudo nix run github:nix-community/disko -- --mode disko /etc/nixos/disko.nix
   sudo nixos-install --flake /etc/nixos#test --root /mnt
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

- Declarative disk layout via [disko](https://github.com/nix-community/disko) (EFI + labeled root)
- Plymouth boot splash and quiet boot
- Auto-login for the `test` user
- Default Adwaita dark wallpaper and reduced GNOME telemetry / software-center nags
- zram, Bluetooth, AppImage, thermald, power management
- Flatpak + Flathub with default apps: Chrome, LibreOffice, Zoom, Firefox, VLC, File Roller
- Weekly auto-upgrade that clones/pulls the repo, takes a btrfs snapshot if applicable, rebuilds, and updates Flatpaks
- Protected generation 1 kept as the automatic fallback
- Firewall enabled, SSH disabled

## Building the live installer ISO

```bash
nix build .#iso
```

Test in a VM with `nix run .#vm`.

## Notes

- The password `t` is intentionally weak for a pure test / lab system.
- Generation 1 is treated as the permanent safe fallback.
- Update the disk path in `disko.nix` before installing on real hardware.
