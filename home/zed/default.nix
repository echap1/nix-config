# Zed, ported from the Mac config. Shared by Linux and macOS.
# The settings themselves are in settings.nix, so Zed on Windows (home/windows) gets them too.
{ pkgs, lib, ... }:
let
  zed = import ./settings.nix {
    # Absolute paths so Zed finds them no matter what PATH it sees.
    # Other language servers are downloaded by Zed as usual (nix-ld handles that on NixOS).
    nixd = lib.getExe pkgs.nixd;
    nixfmt = lib.getExe pkgs.nixfmt;
  };
in
{
  programs.zed-editor = {
    enable = true;
    inherit (zed) extensions;
    userKeymaps = zed.keymaps;

    # Monokai Pro theme pack (billgo/monokai)
    themes.monokai = ./monokai.json;

    # settings.json stays writable. Zed's own UI changes survive, and on each
    # rebuild these values are merged back in and take precedence.
    userSettings = zed.settings;
  };
}
