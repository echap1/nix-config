# nix-darwin system config for the Mac.
{ pkgs, username, ... }:
{
  imports = [ ./cac.nix ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  # If Nix on the Mac came from the Determinate Systems installer, it manages
  # Nix itself: set this to false or activation will fail.
  nix.enable = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.primaryUser = username;
  users.users.${username}.home = "/Users/${username}";

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  programs.zsh.enable = true;
  # Makes fish a valid login shell; switch to it once with: chsh -s /run/current-system/sw/bin/fish
  programs.fish.enable = true;

  security.pam.services.sudo_local.touchIdAuth = true;

  # Set once at first switch; don't change it afterwards.
  system.stateVersion = 6;
}
