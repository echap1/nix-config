# Things specific to this laptop. Everything shared is in modules/nixos.
{ pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  hardware.bluetooth.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  services.fwupd.enable = true; # firmware updates: `fwupdmgr update`

  networking.firewall.allowedTCPPorts = [ 8000 ];

  # Set at install time; don't change it (see `man configuration.nix`).
  system.stateVersion = "26.05";
}
