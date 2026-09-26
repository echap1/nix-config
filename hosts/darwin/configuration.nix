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

  # Login shell: fish. nix-darwin only changes the shell of users it manages,
  # which needs the account's uid. Check yours with `id -u` (the first account on a Mac is 501).
  users.knownUsers = [ username ];
  users.users.${username} = {
    uid = 501;
    home = "/Users/${username}";
    shell = pkgs.fish;
  };

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  programs.zsh.enable = true;
  # Adds fish to /etc/shells so it can be a login shell
  programs.fish.enable = true;

  security.pam.services.sudo_local.touchIdAuth = true;

  # Set once at first switch; don't change it afterwards.
  system.stateVersion = 6;
}
