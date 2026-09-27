# Turns every hosts/<name>/host.nix into a machine.
#
# host.nix describes the machine; the folder can hold anything else it needs
# (default.nix, hardware-configuration.nix, disk.nix):
#
#   {
#     kind = "nixos";           # nixos | darwin | home (Home Manager only: WSL, other distros, servers you don't own)
#     system = "x86_64-linux";  # x86_64-linux | aarch64-linux | aarch64-darwin
#     gui = true;               # desktop apps (Zed, Brave, ...) or command line only
#     features = [ "tailscale" "cac" ];
#   }
#
# The provisioning script (nix run .#provision) writes these for you.
{ inputs }:
let
  inherit (inputs.nixpkgs) lib;

  username = "ethan";

  hostDirs = lib.filterAttrs (
    name: type: type == "directory" && builtins.pathExists (../hosts + "/${name}/host.nix")
  ) (builtins.readDir ../hosts);

  hosts = lib.mapAttrs (
    name: _:
    {
      inherit name;
      gui = false;
      features = [ ];
    }
    // import (../hosts + "/${name}/host.nix")
  ) hostDirs;

  ofKind = kind: lib.filterAttrs (_: host: host.kind == kind) hosts;

  specialArgs = host: {
    inherit inputs username host;
    hasFeature = feature: builtins.elem feature host.features;
  };

  homeModules =
    host:
    [ ../home/core.nix ]
    ++ lib.optional host.gui ../home/gui.nix
    ++ lib.optional (host.kind == "nixos" && host.gui) ../home/linux
    ++ lib.optional (host.kind == "darwin") ../home/darwin;

  homeManagerFor = host: {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
      extraSpecialArgs = specialArgs host;
      users.${username}.imports = homeModules host;
    };
  };

  hostDir = host: ../hosts + "/${host.name}";

  standaloneHome =
    host:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs {
        inherit (host) system;
        config.allowUnfree = true;
      };
      extraSpecialArgs = specialArgs host;
      modules = homeModules host ++ [
        {
          home.username = username;
          home.homeDirectory =
            if lib.hasSuffix "darwin" host.system then "/Users/${username}" else "/home/${username}";
        }
      ];
    };

  # Command-line-only setups for any machine, no host folder needed:
  #   nix run home-manager -- switch --flake .#ethan@x86_64-linux
  genericHomes = lib.listToAttrs (
    map
      (system: {
        name = "${username}@${system}";
        value = standaloneHome {
          name = "${username}-${system}";
          kind = "home";
          inherit system;
          gui = false;
          features = [ ];
        };
      })
      [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ]
  );
in
{
  inherit hosts username;

  nixosConfigurations = lib.mapAttrs (
    _: host:
    lib.nixosSystem {
      specialArgs = specialArgs host;
      modules = [
        { nixpkgs.hostPlatform = host.system; }
        ../modules/nixos
        (hostDir host)
        inputs.home-manager.nixosModules.home-manager
        (homeManagerFor host)
      ];
    }
  ) (ofKind "nixos");

  darwinConfigurations = lib.mapAttrs (
    _: host:
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = specialArgs host;
      modules = [
        { nixpkgs.hostPlatform = host.system; }
        ../modules/darwin
        (hostDir host)
        inputs.home-manager.darwinModules.home-manager
        (homeManagerFor host)
      ];
    }
  ) (ofKind "darwin");

  homeConfigurations = lib.mapAttrs (_: standaloneHome) (ofKind "home") // genericHomes;
}
