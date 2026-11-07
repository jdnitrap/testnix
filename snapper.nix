# snapper.nix — btrfs snapshot layer for testnix
# Sits below NixOS generations and above Powerwash.
# Three tiers of undo: generations (system), snapshots (everything mutable), Powerwash (nuclear).
#
# TODO (not yet wired in):
# 1. Subvolume layout assumes a specific partition scheme. If the disk is not already
#    carved into @, @home, @var, /nix, /boot subvolumes, repartition first — this is
#    the one-time painful part and must happen before enabling this module.
# 2. grub-btrfs for boot-menu snapshot entries is not wired in. That hook is optional
#    and adds complexity; the boot.loader.grub.extraInstallCommands stub below is a
#    placeholder until a decision is made on whether to include it.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Root must be btrfs with subvolumes. Example layout:
  #   /@          (root, snapshotted)
  #   /@home      (home, snapshotted)
  #   /@var       (var, NOT snapshotted — logs and temp churn)
  #   /nix        (nix store, NOT snapshotted — generations already cover it)
  #   /boot       (efi, NOT snapshotted)
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
    options = [ "subvol=@" "compress=zstd" "noatime" ];
  };
  fileSystems."/home" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd" "noatime" ];
  };
  fileSystems."/var" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
    options = [ "subvol=@var" "compress=zstd" "noatime" ];
  };

  services.snapper = {
    snapshotInterval = "hourly";   # cheap on COW; hourly gives fine granularity
    cleanupInterval = "1d";         # prune on a daily cadence
    configs = {
      root = {
        SUBVOLUME = "/";
        ALLOW_USERS = [ "nimda" ];
        TIMELINE_CREATE = true;
        TIMELINE_MIN_AGE = "1800";        # 30 min — skip near-identical snapshots
        TIMELINE_LIMIT_HOURLY = "24";
        TIMELINE_LIMIT_DAILY = "7";
        TIMELINE_LIMIT_WEEKLY = "4";
        TIMELINE_LIMIT_MONTHLY = "3";
        TIMELINE_LIMIT_YEARLY = "0";
      };
      home = {
        SUBVOLUME = "/home";
        ALLOW_USERS = [ "nimda" ];
        TIMELINE_CREATE = true;
        TIMELINE_MIN_AGE = "1800";
        TIMELINE_LIMIT_HOURLY = "24";
        TIMELINE_LIMIT_DAILY = "7";
        TIMELINE_LIMIT_WEEKLY = "4";
        TIMELINE_LIMIT_MONTHLY = "3";
        TIMELINE_LIMIT_YEARLY = "0";
      };
    };
  };

  # Pre-upgrade snapshot: belt and suspenders on top of the timeline.
  # Fires right before the Monday auto-upgrade rebuild boot.
  systemd.services.snapper-pre-upgrade = {
    description = "Snapshot root and home before auto-upgrade";
    before = [ "auto-upgrade.service" ];
    wantedBy = [ "auto-upgrade.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.snapper}/bin/snapper -c root create --description "pre-upgrade" || true
      ${pkgs.snapper}/bin/snapper -c home create --description "pre-upgrade" || true
    '';
  };

  # Boot entry: add a GRUB menu item per snapshot so you can pick one at boot
  # without dropping to a shell. Requires btrfsprogs and snapper's grub-btrfs hook.
  # STUB: grub-btrfs integration not yet decided — see TODO at top of file.
  boot.loader.grub.extraInstallCommands = ''
    ${pkgs.grub2}/bin/grub-mkconfig -o /boot/grub/grub.cfg
  '';
  environment.systemPackages = [ pkgs.snapper pkgs.btrfs-progs ];
}
