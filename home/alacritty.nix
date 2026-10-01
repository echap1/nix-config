# Alacritty, shared by Linux and macOS. Settings are in alacritty-settings.nix so
# Alacritty on Windows (home/windows) gets the same ones.
{ ... }:
{
  programs.alacritty = {
    enable = true;
    settings = import ./alacritty-settings.nix;
  };
}
