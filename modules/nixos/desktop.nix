# Desktop for machines with gui = true: Hyprland, Noctalia shell and greeter,
# file manager, keyring, fonts.
{ pkgs, inputs, ... }:
{
  imports = [ inputs.noctalia-greeter.nixosModules.default ];

  nix.settings = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  hardware.graphics.enable = true;

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  services.displayManager.noctalia-greeter = {
    enable = true;
    settings.keyboard.layout = "us";
  };

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true; # unlock at login

  environment.systemPackages = with pkgs; [
    noctalia
    nautilus
    hyprpolkitagent
    # Installed system-wide so its polkit policy is registered: that's what lets
    # Bitwarden unlock with your system password instead of the master password.
    bitwarden-desktop
  ];

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  services.gvfs.enable = true; # trash, network shares, sftp:// and dav:// in Nautilus
  services.udisks2.enable = true; # mounting USB drives
  programs.dconf.enable = true; # lets Nautilus save its settings

  # Password prompt for mounting and other admin actions
  systemd.packages = [ pkgs.hyprpolkitagent ];
  systemd.user.services.hyprpolkitagent.wantedBy = [ "graphical-session.target" ];

  # "Open in Terminal" in the right-click menu
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "alacritty";
  };
}
