# CAC reader + DoD certificates, system side.
{ pkgs, ... }:
{
  # Smart card daemon (includes the CCID driver most USB CAC readers use)
  services.pcscd.enable = true;

  # DoD roots in the system trust store (curl, git, most CLI tools and apps using OpenSSL)
  security.pki.certificateFiles = [ ../../certs/dod/roots.pem ];

  environment.systemPackages = with pkgs; [
    opensc # PKCS#11 driver for the card
    pcsc-tools # `pcsc_scan` to check the reader sees your card
  ];
}
