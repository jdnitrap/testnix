{ config, lib, pkgs, ... }:
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

  environment.systemPackages = with pkgs; [
    flatpak
    gnome-software
    libnotify
  ];

  # Simplified auto-upgrade (flake-aware)
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
      export PATH=${pkgs.nixos-rebuild}/bin:${pkgs.nix}/bin:$PATH
      nixos-rebuild boot --flake /etc/nixos#test || true
      flatpak update --noninteractive --assumeyes || true
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };

  # Powerwash script (basic: clear user home except essentials)
  environment.systemPackages = with pkgs; [
    (pkgs.writeShellScriptBin "powerwash" ''
      set -eu
      echo "This will wipe user data for the test user. Type YES to continue:"
      read confirm
      if [ "$confirm" != "YES" ]; then
        echo "Aborted."
        exit 1
      fi
      systemctl stop display-manager || true
      rm -rf /home/test/* /home/test/.[!.]* || true
      echo "Powerwash complete. Rebooting..."
      reboot
    '')
  ];
}
