# Things specific to this Mac. Everything shared is in modules/darwin.
{ username, ... }:
{
  # Your account's user ID (`id -u`); nix-darwin needs it to manage your login shell
  users.users.${username}.uid = 501;

  # If Nix on this Mac came from the Determinate Systems installer, it manages
  # Nix itself: set this to false or activation will fail.
  nix.enable = true;

  # Set once at first switch; don't change it afterwards.
  system.stateVersion = 6;
}
