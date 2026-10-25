# testnix

A flake-based, set-and-forget NixOS system with a GNOME Wayland desktop. Inspired by the simplicity goals of projects like nixbook.

| | |
|---|---|
| **Desktop** | GNOME on Wayland (GDM) |
| **User** | `test` (password `t`, auto-login, wheel) |
| **Nixpkgs** | `master` |
| **Disks** | Declarative layout via [disko](https://github.com/nix-community/disko) |
| **Repo** | https://github.com/jdnitrap/testnix |

## Installation (disko)

1. Boot a NixOS installer (or the live ISO below).
2. Clone the repository:
   ```bash
   sudo git clone https://github.com/jdnitrap/testnix.git /etc/nixos
   ```
3. Edit `disko.nix` and replace `/dev/disk/by-id/CHANGE-ME` with your real disk (e.g. `/dev/nvme0n1` or `/dev/sda`).
4. Partition, format, and mount:
   ```bash
   sudo nix run github:nix-community/disko -- --mode disko /etc/nixos/disko.nix
   ```
5. Install:
   ```bash
   sudo nixos-install --flake /etc/nixos#test --root /mnt
   ```
6. Reboot. The system auto-logs in as `test`. Default Flatpak apps install in the background.

## Everyday use

Desktop menu entries under **System**:

- **Update Now** — run the auto-upgrade immediately
- **List Generations** — show available system generations
- **Boot Default Generation** — switch back to the protected generation 1
- **Powerwash** — reset to generation 1, wipe `/home/test`, and reboot

## Features

- Declarative disk layout (disko) with labeled EFI (`boot`) and root partitions
- Plymouth boot splash and quiet boot
- Auto-login for the `test` user
- Adwaita dark wallpaper and reduced GNOME telemetry / software-center nags
- zram, Bluetooth, AppImage, thermald, power management
- Flatpak + Flathub with default apps: Chrome, LibreOffice, Zoom, Firefox, VLC, File Roller
- Weekly auto-upgrade that:
  - clones or pulls this repository to `/etc/nixos`
  - takes a btrfs snapshot of `/` when applicable
  - runs `nixos-rebuild boot --flake /etc/nixos#test`
  - updates Flatpaks
  - shows desktop notifications
- Protected generation 1 kept as the automatic fallback (weekly GC of older generations)
- Firewall enabled, SSH disabled

## Live installer ISO

Build a Calamares-based GNOME live installer:

```bash
nix build .#iso
```

The ISO is in `result/iso/`. Test it in a VM with:

```bash
nix run .#vm
```

## Notes

- The password `t` is intentionally weak and intended only for test or lab use.
- Generation 1 is treated as the permanent safe fallback. The first successful boot after install becomes that generation.
- You must set the real disk path in `disko.nix` before installing on physical hardware.
