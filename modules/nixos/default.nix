# Shared by every NixOS machine. What else gets pulled in depends on the host's
# host.nix: a desktop when gui = true, plus each entry in features.
{ host, lib, ... }:
let
  has = feature: builtins.elem feature host.features;
in
{
  imports = [
    ./common.nix
  ]
  ++ lib.optional host.gui ./desktop.nix
  ++ lib.optional (has "tailscale") ./tailscale.nix
  ++ lib.optional (has "cac") ./cac.nix;
}
