# Everything here works on NixOS, macOS and any other Linux with Nix.
{ pkgs, inputs, ... }:
{
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./zed
    ./fish.nix
    ./alacritty.nix
    ./git.nix
  ];

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  # Neovim config lives in ../nvim so it can also be run on its own with `nix run .#nvim`
  programs.nixvim = {
    enable = true;
    imports = [ ../nvim ];
    nixpkgs.source = inputs.nixpkgs; # same Nixpkgs as the rest of the system
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    ripgrep
    fd
    jq
    lazygit
    btop
  ];

  # Makes fonts from home.packages visible to apps (on macOS they go to ~/Library/Fonts)
  fonts.fontconfig.enable = true;
}
