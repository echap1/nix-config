# Command-line setup for every machine: servers, WSL, desktops, Macs.
{ pkgs, inputs, ... }:
{
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./fish.nix
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
    ripgrep
    fd
    jq
    lazygit
    btop
  ];
}
