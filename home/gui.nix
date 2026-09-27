# Desktop apps for machines with gui = true (Linux desktops and Macs).
{
  pkgs,
  lib,
  host,
  ...
}:
{
  imports = [
    ./zed
    ./alacritty.nix
  ];

  home.packages =
    with pkgs;
    [
      nerd-fonts.jetbrains-mono
      discord
      obsidian
    ]
    # Bitwarden comes from the NixOS system config (for system-password unlock) and
    # from Homebrew on Macs (for Touch ID); only other Linux desktops need it here.
    ++ lib.optional (pkgs.stdenv.hostPlatform.isLinux && host.kind != "nixos") bitwarden-desktop;

  # Brave, with the Bitwarden extension. Bookmarks, history and open tabs sync
  # between machines with Brave Sync (Settings > Sync), set up once per machine.
  programs.chromium = {
    enable = true;
    package = pkgs.brave;
    extensions = [
      "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
    ];
  };

  # Makes fonts from home.packages visible to apps (on macOS they go to ~/Library/Fonts)
  fonts.fontconfig.enable = true;
}
