# macOS-only user settings. Shared stuff (Neovim, Zed, Brave, CLI tools) comes from common.nix.
# GUI apps installed through Nix are copied to ~/Applications/Home Manager Apps.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Mac-only tools go here
  ];

  # Tiling window manager, Hyprland-style keys on alt. Config is your aerospace.toml as-is.
  programs.aerospace = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ./aerospace.toml);
    # Started at login by launchd (and restarted if it quits)
    launchd.enable = true;
  };
}
