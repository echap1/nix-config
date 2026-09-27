# Written by nix run .#provision. See lib/default.nix for what these mean.
{
  kind = "nixos";
  system = "x86_64-linux";
  gui = true;
  features = [ "tailscale" "cac" ];
}
