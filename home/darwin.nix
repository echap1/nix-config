# macOS-only user settings. Shared stuff (Neovim, Zed, CLI tools) comes from common.nix.
# GUI apps installed through Nix are copied to ~/Applications/Home Manager Apps.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Mac-only tools go here
  ];
}
