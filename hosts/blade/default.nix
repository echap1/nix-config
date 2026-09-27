# Things specific to blade. Everything shared is in modules/nixos.
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disk.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # The NixOS release this machine was first installed with; don't change it.
  system.stateVersion = "26.11";
}
