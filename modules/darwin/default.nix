# Shared by every Mac. Extras come from the host's host.nix features.
{
  host,
  lib,
  pkgs,
  username,
  ...
}:
let
  has = feature: builtins.elem feature host.features;
in
{
  imports = [
    ./defaults.nix
    ./homebrew.nix
  ]
  ++ lib.optional (has "cac") ./cac.nix;

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  networking.hostName = host.name;
  system.primaryUser = username;

  # Login shell: fish. nix-darwin only changes the shell of users it manages,
  # which needs the account's uid (set per Mac in hosts/<name>/default.nix).
  users.knownUsers = [ username ];
  users.users.${username} = {
    home = "/Users/${username}";
    shell = pkgs.fish;
  };

  programs.zsh.enable = true;
  programs.fish.enable = true; # adds fish to /etc/shells

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  security.pam.services.sudo_local.touchIdAuth = true;

  # Tailscale: the Mac app (menu bar, sign-in, Taildrive sharing) via Homebrew
  homebrew.casks = lib.optional (has "tailscale") "tailscale-app";
}
