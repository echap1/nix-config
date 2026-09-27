# Mac apps that aren't in Nixpkgs (or need Apple's signing for Touch ID), installed
# with Homebrew. nix-homebrew installs Homebrew itself, so a fresh Mac needs nothing first.
{ inputs, username, ... }:
{
  imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

  nix-homebrew = {
    enable = true;
    user = username;
    autoMigrate = true; # take over an existing Homebrew install instead of failing
  };

  homebrew = {
    enable = true;
    casks = [
      "claude"
      # The signed app, so Touch ID unlock and browser integration work
      "bitwarden"
    ];
    onActivation = {
      upgrade = true;
      # Leaves Homebrew apps not listed here alone. Set to "zap" to have the
      # list above be the only casks installed.
      cleanup = "none";
    };
  };
}
