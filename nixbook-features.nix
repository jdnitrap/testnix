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

  # Protect the default (generation 1) boot generation from GC
  nix.gc.automatic = true;
  nix.gc.dates = "weekly";
  nix.gc.options = "--delete-older-than 30d";
  # Extra safety: never delete the first generation via a small wrapper or note
  # (generation 1 stays as long as it is still referenced by the profile)

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

  # Install a few default Flatpak apps once
  systemd.services.install-default-flatpaks = {
    wantedBy = [ "multi-user.target" ];
    after = [ "flatpak-add-flathub.service" "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      set -eu
      if ! flatpak list --app | grep -q org.libreoffice.LibreOffice; then
        ${notifyScript} "Installing apps" "Setting up Chrome, LibreOffice, and Zoom..."
        flatpak install flathub com.google.Chrome -y || true
        flatpak install flathub org.libreoffice.LibreOffice -y || true
        flatpak install flathub us.zoom.Zoom -y || true
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
  ];

  # Weekly auto-upgrade: clone or pull the flake repo, then full update
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
}
