{ config, lib, pkgs, modulesPath, ... }:
{
  # PLACEHOLDER ONLY.
  # On a real install, run this on the target laptop and it will overwrite this file
  # with the correct disk UUIDs, kernel modules, and firmware for that machine:
  #
  #   sudo nixos-generate-config --root /mnt
  #
  # Do not use the UUIDs below as-is.

  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # PLACEHOLDERS ONLY — will not boot if used as-is.
  fileSystems."/" =
    { device = "/dev/disk/by-uuid/11111111-1111-1111-1111-111111111111";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/2222-2222";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
