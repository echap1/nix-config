# The Framework laptop
{
  kind = "nixos";
  system = "x86_64-linux";
  gui = true;
  features = [
    "tailscale"
    "cac"
  ];
}
