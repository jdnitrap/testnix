# testnix

Flake-based NixOS test project. GNOME on Wayland, set-and-forget appliance style.

## First-boot flow

1. Clone or boot from the Calamares ISO (removed; use a standard NixOS installer).
2. Partition the disk yourself (no disko anymore).
3. Run `sudo nixos-generate-config --root /mnt` on the target laptop to create the real `hardware-configuration.nix`.
4. Copy your flake in, point `hardware-configuration.nix` at the generated file, then:
   ```bash
   sudo nixos-install --flake /mnt/etc/nixos#test --root /mnt
   ```
5. Reboot. Auto-login as `test`, GNOME starts, Flatpaks install in the background.

## Everyday menu entries (GNOME)

- **Update Now** — runs the weekly auto-upgrade immediately
- **List Generations** — shows system generations; generation 1 is the fallback
- **Boot Default Generation** — switches to generation 1
- **Powerwash** — switches to generation 1, wipes `/home/test`, rebuilds the standard home folders (Desktop, Documents, Downloads, Pictures, `.local/share`) from `/etc/testnix/config`, then reboots. The `test` account itself is declared in the flake and is never deleted.

## Features

- Flake on nixpkgs **master**
- GNOME on Wayland via GDM, auto-login for `test`
- Firewall on, SSH off
- NetworkManager, PipeWire, printing
- zram (50% of RAM), Bluetooth, AppImage support, thermald
- Flatpak + Flathub, default apps: Chrome, LibreOffice, Zoom, Firefox, VLC, File Roller
- Weekly auto-upgrade: hard-reset `/etc/nixos` to `origin/main`, `nixos-rebuild boot`, Flatpak update, notifications
- Custom Plymouth splash (testnix ring theme) + matching GNOME wallpaper
- GNOME polish: favorites, dark wallpaper, telemetry/software nags reduced
- `users.mutableUsers = true` so `passwd` works after first boot
- Starter home files in `config/` deployed to `/etc/testnix/config`

## Notes

- Password for `test` is `t` — extremely weak, lab only.
- Generation 1 is the permanent fallback; Powerwash and Boot Default Generation check it exists first.
- No disk encryption.
- The Monday timer has no fixed time of day.
- No CI: a broken flake on master is only caught when rebuild runs.
