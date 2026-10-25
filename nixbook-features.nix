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
  ];

  # Weekly auto-upgrade with notifications
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
      export PATH=${pkgs.nixos-rebuild}/bin:${pkgs.nix}/bin:${pkgs.coreutils}/bin:$PATH
      ${notifyScript} "System updates" "Updates are installing in the background."
      if [ -d /etc/nixos ]; then
        nixos-rebuild boot --flake /etc/nixos#test || true
      fi
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

  # Powerwash as a desktop entry + script
  environment.systemPackages = with pkgs; [
    (pkgs.writeShellScriptBin "powerwash" ''
      set -eu
      ${pkgs.zenity}/bin/zenity --question --title="Powerwash" --text="This will wipe all data for the test user and reboot. Continue?" || exit 1
      systemctl stop display-manager || true
      rm -rf /home/test/* /home/test/.[!.]* || true
      ${notifyScript} "Powerwash" "User data cleared. Rebooting..."
      reboot
    '')

    (pkgs.makeDesktopItem {
      name = "powerwash";
      desktopName = "Powerwash";
      comment = "Wipe user data and reset";
      exec = "pkexec powerwash";
      icon = "edit-clear";
      categories = [ "System" ];
    })
  ];
}
