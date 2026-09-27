# Disk layout for machines installed with nixos-anywhere. A host opts in from its
# disk.nix (written by the provision script):
#
#   { imports = [ ../../modules/disko ]; disk = { device = "/dev/nvme0n1"; encrypt = true; }; }
#
# Wipes the whole disk: 1 GB EFI boot partition (plus a 1 MB one for BIOS machines), then Btrfs on the rest (optionally
# inside LUKS) with subvolumes for /, /home, /nix and swap.
{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.disk;

  btrfs = {
    type = "btrfs";
    extraArgs = [ "-f" ];
    subvolumes = {
      "@root" = {
        mountpoint = "/";
        mountOptions = [
          "compress=zstd"
          "noatime"
        ];
      };
      "@home" = {
        mountpoint = "/home";
        mountOptions = [
          "compress=zstd"
          "noatime"
        ];
      };
      "@nix" = {
        mountpoint = "/nix";
        mountOptions = [
          "compress=zstd"
          "noatime"
        ];
      };
      "@swap" = {
        mountpoint = "/.swapvol";
        swap.swapfile.size = cfg.swapSize;
      };
    };
  };
in
{
  imports = [ inputs.disko.nixosModules.disko ];

  options.disk = {
    device = lib.mkOption {
      type = lib.types.str;
      example = "/dev/nvme0n1";
      description = "Disk to wipe and install onto.";
    };
    encrypt = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Full-disk encryption (LUKS). You type the passphrase at every boot, so leave it off for unattended servers.";
    };
    swapSize = lib.mkOption {
      type = lib.types.str;
      default = "8G";
    };
  };

  config.disko.devices.disk.main = {
    type = "disk";
    inherit (cfg) device;
    content = {
      type = "gpt";
      partitions = {
        # Tiny partition GRUB needs on legacy-BIOS machines; unused on UEFI
        bios = {
          size = "1M";
          type = "EF02";
          priority = 1;
        };
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content =
            if cfg.encrypt then
              {
                type = "luks";
                name = "cryptroot";
                # Only read while installing; nixos-anywhere copies your passphrase here
                passwordFile = "/tmp/disk.key";
                settings.allowDiscards = true;
                content = btrfs;
              }
            else
              btrfs;
        };
      };
    };
  };
}
