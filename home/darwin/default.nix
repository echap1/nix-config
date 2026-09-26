# macOS-only user settings. Shared stuff (Neovim, Zed, Brave, CLI tools) comes from common.nix.
# GUI apps installed through Nix are copied to ~/Applications/Home Manager Apps.
{ lib, pkgs, ... }:
{
  home.packages = with pkgs; [
    # Mac-only tools go here
  ];

  # Desktop wallpaper, set on every switch. The first time, macOS asks to let your
  # terminal control System Events; allow it.
  home.activation.wallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run /usr/bin/osascript -e 'tell application "System Events" to tell every desktop to set picture to POSIX file "${../../wallpapers/wallpaper.png}"' \
      || echo "warning: couldn't set the wallpaper" >&2
  '';

  # Tiling window manager, Hyprland-style keys on alt. Config is your aerospace.toml as-is.
  programs.aerospace = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ./aerospace.toml);
    # Started at login by launchd (and restarted if it quits)
    launchd.enable = true;
  };
}
