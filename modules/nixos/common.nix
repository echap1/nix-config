# Base system for every NixOS machine, desktop or server.
{
  pkgs,
  host,
  username,
  ...
}:
{
  networking.hostName = host.name;
  networking.networkmanager.enable = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      username
    ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.optimise.automatic = true;
  nixpkgs.config.allowUnfree = true;

  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  users.users.${username} = {
    isNormalUser = true;
    description = username;
    shell = pkgs.fish;
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "input"
    ];
    # SSH public keys you add to keys/ (e.g. a YubiKey-backed ed25519-sk key)
    openssh.authorizedKeys.keyFiles = map (f: ../../keys + "/${f}") (
      builtins.filter (f: builtins.match ".*\\.pub" f != null) (
        builtins.attrNames (builtins.readDir ../../keys)
      )
    );
  };
  security.sudo.wheelNeedsPassword = false;

  programs.fish.enable = true;
  environment.systemPackages = [ pkgs.git ];

  # SSH, reachable only over Tailscale (see tailscale.nix). Also gives the machine
  # the host key sops-nix uses to decrypt secrets.
  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Lets prebuilt Linux binaries (Zed's language servers, its Node runtime,
  # VS Code extensions and the like) run on NixOS
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      openssl
      icu # needed by .NET-based servers (C#, PowerShell)
      libgcc
    ];
  };
}
