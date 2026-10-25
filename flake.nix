{
  description = "Flake-based NixOS test project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, disko }:
  let
    system = "x86_64-linux";
  in
  {
    nixosConfigurations = {
      test = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          disko.nixosModules.disko
          ./disko.nix
          ./configuration.nix
        ];
      };

      # Calamares-based live installer ISO.
      # The ISO itself is stock GNOME + Calamares. The testnix .nix files are
      # copied into the ISO store so they can be inspected or used manually
      # after boot. They are not automatically applied by the live session.
      installer = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-gnome.nix"
          {
            isoImage.edition = "testnix";
            isoImage.volumeID = "TESTNIX";
            system.stateVersion = "26.05";

            # Auto-login for the live session
            services.displayManager.autoLogin.enable = true;
            services.displayManager.autoLogin.user = "nixos";

            # Copies of the config for reference on the live media
            isoImage.storeContents = [
              ./configuration.nix
              ./nixbook-features.nix
              ./hardware-configuration.nix
              ./disko.nix
              ./plymouth-theme.nix
              ./wallpaper.nix
            ];
          }
        ];
      };
    };

    packages.${system} = {
      iso = self.nixosConfigurations.installer.config.system.build.isoImage;
      vm = self.nixosConfigurations.installer.config.system.build.vm;
    };
  };
}
