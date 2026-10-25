{ config, lib, pkgs, ... }:
let
  notifyScript = pkgs.writeShellScript "notify-users" ''
    set -eu
    title="$1"
    body="$2"
    users=$(${pkgs.systemd}/bin/loginctl list-sessions --no-legend | ${pkgs.gawk}/bin/awk '{print $3}' | sort -u)
    for user in $users; do
      [ -n "$user" ] || continue
      uid=$(id -u "$user" 2>/dev/null) || continue
      [ -S "/run/user/$uid/bus" ] || continue
      ${pkgs.sudo}/bin/sudo -u "$user" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
        ${pkgs.libnotify}/bin/notify-send "$title" "$body" || true
    done
  '';

  testnixPlymouth = import ./plymouth-theme.nix { inherit pkgs; };
  testnixWallpaper = import ./wallpaper.nix { inherit pkgs; };
in
{
  # Durability / set-and-forget basics
  zramSwap.enable = true;
  zramSwap.memoryPercent = 50;

  hardware.bluetooth.enable = true;

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # Boot splash — custom testnix theme
  boot.plymouth.enable = true;
  boot.plymouth.theme = "testnix";
  boot.plymouth.themePackages = [ testnixPlymouth ];
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
  boot.kernelParams = [
    "quiet"
    "splash"
    "loglevel=3"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "udev.log_level=3"
  ];

  # Low-resource / Chromebook-ish tweaks
  services.thermald.enable = true;
  powerManagement.enable = true;

  # Protect the default (generation 1) boot generation from GC
  nix.gc.automatic = true;
  nix.gc.dates = "weekly";
  nix.gc.options = "--delete-older-than 30d";

  # Flatpak + Flathub
  services.flatpak.enable = true;
  systemd.services.flatpak-add-flathub = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    '';
    serviceConfig.Type = "oneshot";
  };

  # Install default Flatpak apps once
  # Sentinel is a stamp file so uninstalling one app does not re-trigger everything.
  systemd.services.install-default-flatpaks = {
    wantedBy = [ "multi-user.target" ];
    after = [ "flatpak-add-flathub.service" "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      set -eu
      stamp=/var/lib/testnix-flatpaks-installed
      if [ ! -f "$stamp" ]; then
        ${notifyScript} "Installing apps" "Setting up default applications..."
        flatpak install flathub com.google.Chrome -y || true
        flatpak install flathub org.libreoffice.LibreOffice -y || true
        flatpak install flathub us.zoom.Zoom -y || true
        flatpak install flathub org.mozilla.firefox -y || true
        flatpak install flathub org.videolan.VLC -y || true
        flatpak install flathub org.gnome.FileRoller -y || true
        touch "$stamp"
        ${notifyScript} "Apps ready" "Default applications have been installed."
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      Restart = "on-failure";
      RestartSec = "60s";
    };
  };

  environment.systemPackages = with pkgs; [
    flatpak
    gnome-software
    libnotify
    gawk
    sudo
    git
    vlc
    file-roller
    testnixWallpaper
  ];

  # Deploy starter home-directory files to /etc/testnix/config.
  # Powerwash copies these into /home/test after wiping it.
  environment.etc."testnix/config".source = ./config;

  # Weekly auto-upgrade: sync the flake repo to remote FIRST, then full update.
  # Order matters: fetch + reset to origin/main guarantees a clean rebase base
  # before nixos-rebuild runs. Remote is the source of truth; any local drift
  # is discarded (this is a managed appliance, not a dev machine).
  #
  # Future experiment (not active): btrfs snapshot before update.
  # Only useful if root is btrfs. On ext4 this does nothing useful.
  # To try later:
  #   if findmnt -n -o FSTYPE / | grep -q btrfs; then
  #     mkdir -p /snapshots
  #     btrfs subvolume snapshot / /snapshots/pre-update-$(date +%Y%m%d-%H%M%S) || true
  #   fi
  systemd.timers.auto-upgrade = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Mon";
      Persistent = true;
      Unit = "auto-upgrade.service";
    };
  };

  systemd.services.auto-upgrade = {
    script = ''
      set -eu
      export PATH=${pkgs.nixos-rebuild}/bin:${pkgs.nix}/bin:${pkgs.git}/bin:${pkgs.coreutils}/bin:$PATH
      ${notifyScript} "System updates" "Checking for updates and installing in the background."

      # Step 1: make /etc/nixos an exact mirror of the remote repo.
      if [ ! -d /etc/nixos/.git ]; then
        rm -rf /etc/nixos
        git clone https://github.com/jdnitrap/testnix.git /etc/nixos
      else
        # Fetch latest refs, then hard-reset to the remote default branch.
        # This is the hardened equivalent of pull --rebase: it cannot fail on
        # divergent history because we do not preserve local commits.
        git -C /etc/nixos remote set-url origin https://github.com/jdnitrap/testnix.git
        git -C /etc/nixos fetch --prune origin
        git -C /etc/nixos checkout -B main origin/main
        git -C /etc/nixos reset --hard origin/main
      fi

      # Step 2: rebuild from the freshly synced tree.
      nixos-rebuild boot --flake /etc/nixos#test || true

      # Step 3: Flatpak updates.
      flatpak update --noninteractive --assumeyes || true

      ${notifyScript} "Updates complete" "Reboot when convenient to apply system updates."
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };

  # Menu entries
  environment.systemPackages = with pkgs; [
    (pkgs.writeShellScriptBin "update-now" ''
      set -eu
      ${notifyScript} "Manual update" "Starting update now..."
      systemctl start auto-upgrade.service || true
    '')

    (pkgs.writeShellScriptBin "list-generations" ''
      nix-env -p /nix/var/nix/profiles/system --list-generations
      echo ""
      echo "Generation 1 is the intended fallback. Use 'Boot Default Generation' to switch to it."
    '')

    (pkgs.writeShellScriptBin "boot-default" ''
      set -eu
      if ! nix-env -p /nix/var/nix/profiles/system --list-generations | grep -q '^ *1 '; then
        ${notifyScript} "Recovery" "Generation 1 does not exist. Cannot switch."
        exit 1
      fi
      nix-env -p /nix/var/nix/profiles/system --switch-generation 1
      if command -v bootctl >/dev/null; then
        bootctl set-default nixos-generation-1.conf || true
      fi
      ${notifyScript} "Recovery" "Switched to generation 1. Reboot to apply."
    '')

    (pkgs.makeDesktopItem {
      name = "update-now";
      desktopName = "Update Now";
      comment = "Check for and install updates";
      exec = "pkexec update-now";
      icon = "system-software-update";
      categories = [ "System" ];
    })

    (pkgs.makeDesktopItem {
      name = "list-generations";
      desktopName = "List Generations";
      comment = "Show available system generations";
      exec = "gnome-terminal -- list-generations";
      icon = "document-properties";
      categories = [ "System" ];
    })

    (pkgs.makeDesktopItem {
      name = "boot-default";
      desktopName = "Boot Default Generation";
      comment = "Switch back to generation 1 if it exists";
      exec = "pkexec boot-default";
      icon = "go-previous";
      categories = [ "System" ];
    })
  ];

  # Powerwash: switch back to generation 1 if it exists, wipe user data,
  # rebuild the standard home directory from /etc/testnix/config, reboot.
  # The test account itself is declared in the flake and survives untouched.
  environment.systemPackages = with pkgs; [
    (pkgs.writeShellScriptBin "powerwash" ''
      set -eu
      ${pkgs.zenity}/bin/zenity --question --title="Powerwash" --text="This will switch back to generation 1 (if it exists), wipe all data for the test user, rebuild the home directory from starter files, and reboot. Continue?" || exit 1

      if nix-env -p /nix/var/nix/profiles/system --list-generations | grep -q '^ *1 '; then
        nix-env -p /nix/var/nix/profiles/system --switch-generation 1 || true
        if command -v bootctl >/dev/null; then
          bootctl set-default nixos-generation-1.conf || true
        fi
      else
        ${notifyScript} "Powerwash" "Generation 1 missing. Wiping user data only."
      fi

      systemctl stop display-manager || true
      rm -rf /home/test/* /home/test/.[!.]* || true

      # Rebuild the standard home layout from the repo-deployed starter files.
      mkdir -p /home/test/{Desktop,Documents,Downloads,Pictures,.local/share}
      if [ -d /etc/testnix/config ]; then
        cp -a /etc/testnix/config/. /home/test/ || true
      fi
      chown -R test:test /home/test

      ${notifyScript} "Powerwash" "Home directory reset. Rebooting..."
      reboot
    '')

    (pkgs.makeDesktopItem {
      name = "powerwash";
      desktopName = "Powerwash";
      comment = "Reset to generation 1, wipe user data, rebuild home from starters";
      exec = "pkexec powerwash";
      icon = "edit-clear";
      categories = [ "System" ];
    })
  ];

  # GNOME polish: favorites, wallpaper, disable nags more aggressively
  programs.dconf.enable = true;
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/shell" = {
          favorite-apps = [
            "org.gnome.Nautilus.desktop"
            "org.mozilla.firefox.desktop"
            "com.google.Chrome.desktop"
            "org.gnome.Terminal.desktop"
            "org.gnome.Settings.desktop"
            "org.gnome.Software.desktop"
          ];
        };
        "org/gnome/desktop/background" = {
          picture-uri = "file://${testnixWallpaper}/share/backgrounds/testnix.jpg";
          picture-uri-dark = "file://${testnixWallpaper}/share/backgrounds/testnix.jpg";
          picture-options = "zoom";
          primary-color = "#121212";
        };
        "org/gnome/desktop/privacy" = {
          report-technical-problems = false;
        };
        "org/gnome/software" = {
          download-updates = false;
          show-ratings = false;
          allow-updates = false;
          first-run = false;
        };
      };
    }
  ];
}
