# `nix run .#provision`: the setup dialog in provision.sh, with every tool it uses.
{
  lib,
  stdenv,
  writeShellApplication,
  gum,
  git,
  openssh,
  openssl,
  sops,
  age,
  age-plugin-yubikey,
  ssh-to-age,
  yq-go,
  nixos-anywhere,
  coreutils,
  gnused,
  gawk,
  gnugrep,
  ...
}:
let
  runtimeInputs = [
    gum
    git
    openssh
    openssl
    sops
    age
    age-plugin-yubikey
    ssh-to-age
    yq-go
    nixos-anywhere
    coreutils
    gnused
    gawk
    gnugrep
  ];
in
(writeShellApplication {
  name = "provision";
  inherit runtimeInputs;
  text = builtins.readFile ./provision.sh;
}).overrideAttrs
  (old: {
    passthru = (old.passthru or { }) // {
      inherit runtimeInputs;
    };
  })
