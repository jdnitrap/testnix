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

  # Install more default Flatpak apps once
  systemd.services.install-default-flatpaks = {
    wantedBy = [ "multi-user.target" ];
    after = [ "flatpak-add-flathub.service" "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      set -eu
      if ! flatpak list --app | grep -q org.libreoffice.LibreOffice; then
        ${notifyScript} "Installing apps" "Setting up default applications..."
        flatpak install flathub com.google.Chrome -y || true
        flatpak install flathub org.libreoffice.LibreOffice -y || true
        flatpak install flathub us.zoom.Zoom -y || true
        flatpak install flathub org.mozilla.firefox -y || true
        flatpak install flathub org.videolan.VLC -y || true
        flatpak install flathub org.gnome.FileRoller -y || true
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
    btrfs-progs
    testnixWallpaper
  ];

  # Weekly auto-upgrade: clone or pull the flake repo, snapshot if btrfs, then full update
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
      export PATH=${pkgs.nixos-rebuild}/bin:${pkgs.nix}/bin:${pkgs.git}/bin:${pkgs.coreutils}/bin:${pkgs.btrfs-progs}/bin:$PATH
      ${notifyScript} "System updates" "Checking for updates and installing in the background."

      # Snapshot before update if root is btrfs
      if findmnt -n -o FSTYPE / | grep -q btrfs; then
        btrfs subvolume snapshot / /snapshots/pre-update-$(date +%Y%m%d-%H%M%S) || true
      fi

      if [ ! -d /etc/nixos/.git ]; then
        rm -rf /etc/nixos
        git clone https://github.com/jdnitrap/testnix.git /etc/nixos
      else
        git -C /etc/nixos pull --rebase || true
      fi

      nixos-rebuild boot --flake /etc/nixos#test || true
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
      echo "Current default is generation 1 (protected fallback)."
    '')

    (pkgs.writeShellScriptBin "boot-default" ''
      set -eu
      nix-env -p /nix/var/nix/profiles/system --switch-generation 1 || true
      if command -v bootctl >/dev/null; then
        bootctl set-default nixos-generation-1.conf || true
      fi
      ${notifyScript} "Recovery" "Switched to default generation 1. Reboot to apply."
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
      comment = "Switch back to the protected generation 1";
      exec = "pkexec boot-default";
      icon = "go-previous";
      categories = [ "System" ];
    })
  ];

  # Powerwash: switch back to default generation 1, wipe user data, reboot
  environment.systemPackages = with pkgs; [
    (pkgs.writeShellScriptBin "powerwash" ''
      set -eu
      ${pkgs.zenity}/bin/zenity --question --title="Powerwash" --text="This will switch back to the default boot generation, wipe all data for the test user, and reboot. Continue?" || exit 1

      # Switch to the protected default generation (generation 1)
      nix-env -p /nix/var/nix/profiles/system --switch-generation 1 || true
      # For systemd-boot, also set it as the default entry if possible
      if command -v bootctl >/dev/null; then
        bootctl set-default nixos-generation-1.conf || true
      fi

      systemctl stop display-manager || true
      rm -rf /home/test/* /home/test/.[!.]* || true

      ${notifyScript} "Powerwash" "Switched to default generation and cleared user data. Rebooting..."
      reboot
    '')

    (pkgs.makeDesktopItem {
      name = "powerwash";
      desktopName = "Powerwash";
      comment = "Reset to default generation and wipe user data";
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
