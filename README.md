# testnix

Flake-based NixOS test project. GNOME on Wayland, set-and-forget appliance style.

Repo: https://github.com/jdnitrap/testnix

## Use on an existing NixOS machine

1. Clone into `/etc/nixos`:
   ```bash
   sudo git clone https://github.com/jdnitrap/testnix.git /etc/nixos
   ```
2. Generate the hardware config for *this* machine (creates the real `hardware-configuration.nix`):
   ```bash
   sudo nixos-generate-config
   ```
3. Switch:
   ```bash
   sudo nixos-rebuild switch --flake /etc/nixos#test
   ```

The flake imports `./hardware-configuration.nix`. That file is not shipped in the repo; it is created on the machine by `nixos-generate-config`.

## Fresh install (from a NixOS installer ISO)

1. Partition and format the disk yourself.
2. Mount root (and `/boot` if separate).
3. Clone:
   ```bash
   sudo git clone https://github.com/jdnitrap/testnix.git /mnt/etc/nixos
   ```
4. Generate hardware config:
   ```bash
   sudo nixos-generate-config --root /mnt
   ```
5. Install:
   ```bash
   sudo nixos-install --flake /mnt/etc/nixos#test --root /mnt
   ```
6. Reboot. Auto-login as `test`.

## Everyday menu entries (GNOME)

- **Update Now** — runs the weekly auto-upgrade immediately
- **List Generations** — shows system generations; generation 1 is the fallback
- **Boot Default Generation** — switches to generation 1
- **Powerwash** — switches to generation 1, wipes `/home/test`, rebuilds the standard home folders from `/etc/testnix/config`, then reboots. The `test` account itself is declared in the flake and is never deleted.

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
- Disko and the Calamares installer ISO were removed. Partition yourself or use the normal NixOS installer.

## Future ideas

- Make the starter home config (`config/` directory deployed to `/etc/testnix/config`) a git submodule or separate small repo, so it can be iterated on independently of the main flake without touching the core system config.
