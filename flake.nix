{
  description = "Ethan's NixOS, macOS and portable Home Manager config";

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
    nixvim = {
      url = "github:nix-community/nixvim";
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
    inputs@{
      nixpkgs,
      home-manager,
      nix-darwin,
      nixvim,
      ...
    }:
    let
      # Change this if your macOS account name is different.
      username = "ethan";

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # Shared by the NixOS and nix-darwin Home Manager setups.
      hmSettings = homeModules: {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          extraSpecialArgs = { inherit inputs; };
          users.${username}.imports = homeModules;
        };
      };
    in
    {
      # Laptop: sudo nixos-rebuild switch --flake .#nixos
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs username; };
        modules = [
          ./hosts/nixos/configuration.nix
          inputs.noctalia-greeter.nixosModules.default
          home-manager.nixosModules.home-manager
          (hmSettings [
            ./home/common.nix
            ./home/linux
          ])
        ];
      };

      # Mac: sudo darwin-rebuild switch --flake .#mac
      # (first time: sudo nix run nix-darwin -- switch --flake .#mac)
      darwinConfigurations.mac = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs username; };
        modules = [
          ./hosts/darwin/configuration.nix
          home-manager.darwinModules.home-manager
          (hmSettings [
            ./home/common.nix
            ./home/darwin.nix
          ])
        ];
      };

      # Any machine with Nix (another distro, a server, a Mac without nix-darwin):
      #   nix run home-manager -- switch --flake .#ethan@x86_64-linux
      # Installs only the shared parts: shell tools, Neovim, Zed.
      homeConfigurations = nixpkgs.lib.listToAttrs (
        map (system: {
          name = "${username}@${system}";
          value = home-manager.lib.homeManagerConfiguration {
            pkgs = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
            extraSpecialArgs = { inherit inputs; };
            modules = [
              ./home/common.nix
              {
                home.username = username;
                home.homeDirectory =
                  if nixpkgs.lib.hasSuffix "darwin" system then "/Users/${username}" else "/home/${username}";
              }
            ];
          };
        }) systems
      );

      # Just the editor, on any machine with Nix, nothing installed:
      #   nix run .#nvim        (or: nix run github:<you>/<repo>#nvim)
      packages = forAllSystems (system: {
        nvim = nixvim.legacyPackages.${system}.makeNixvimWithModule {
          pkgs = nixpkgs.legacyPackages.${system};
          module = ./nvim;
        };
        default = inputs.self.packages.${system}.nvim;
      });

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
