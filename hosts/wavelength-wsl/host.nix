# Written by nix run .#provision. See lib/default.nix for what these mean.
{
  kind = "home";
  system = "x86_64-linux";
  gui = false;
  features = [ "windows" ]; # Zed, Alacritty, GlazeWM, Zebar on the Windows side
}
