{
  description = "Ethan's machines: NixOS, macOS, and Home Manager anywhere else";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Linux desktop only
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-desktop = {
      url = "github:nmcbride/claude-desktop-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ nixpkgs, nixvim, ... }:
    let
      # Every folder in hosts/ with a host.nix becomes a machine (see lib/default.nix)
      machines = import ./lib { inherit inputs; };

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      inherit (machines) nixosConfigurations darwinConfigurations homeConfigurations;

      # Just the editor, on any machine with Nix, nothing installed:
      #   nix run .#nvim        (or: nix run github:<you>/nix-config#nvim)
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          nvim = nixvim.legacyPackages.${system}.makeNixvimWithModule {
            inherit pkgs;
            module = ./nvim;
          };
          default = inputs.self.packages.${system}.nvim;

          # Set up a new machine: nix run .#provision
          provision = pkgs.callPackage ./scripts/provision.nix { inherit inputs; };
        }
      );

      apps = forAllSystems (system: {
        provision = {
          type = "app";
          program = nixpkgs.lib.getExe inputs.self.packages.${system}.provision;
          meta.description = "Set up this or another machine from this repo";
        };
      });

      # Tools for working on this repo (nixos-anywhere, gum, ...): nix develop
      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          packages = inputs.self.packages.${system}.provision.runtimeInputs;
        };
      });

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
