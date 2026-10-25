{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./nixbook-features.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "testnix";

  # Enable networking
  networking.networkmanager.enable = true;

  # Firewall enabled, SSH disabled
  networking.firewall.enable = true;
  services.openssh.enable = false;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable the GNOME Desktop Environment (Wayland via GDM).
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Auto-login for the test user (appliance style)
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "test";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Allow password changes with passwd (default is true, set explicitly)
  users.mutableUsers = true;

  # Define the admin user account.
  users.users.test = {
    isNormalUser = true;
    description = "test";
    extraGroups = [ "networkmanager" "wheel" ];
    hashedPassword = "$6$DU.lGQf.QJKZKClB$iAubTwq72192phdKXub5XjuHlW7QHzP.Iz.WqLX1.xTs8bebPK5BjL8RwQw7.QPra5vhaUdjgBElsDT9TEUKM1";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    gnome-tweaks
  ];

  system.stateVersion = "26.05";
}
