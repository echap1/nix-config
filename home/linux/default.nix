# Linux desktop only: Hyprland, Noctalia, cursor, Claude Desktop, GTK theming.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  wallpaper = ../../wallpapers/wallpaper.png;
  noctalia = lib.getExe config.programs.noctalia.package;
  # Noctalia saves a wallpaper picked in its UI to settings.toml, which beats config.toml.
  # Setting it over IPC each time the shell starts keeps the one from this repo.
  setWallpaper = pkgs.writeShellScript "noctalia-set-wallpaper" ''
    for _ in $(seq 1 20); do
      ${noctalia} msg wallpaper-set ${wallpaper} >/dev/null 2>&1 && exit 0
      sleep 0.5
    done
  '';
in
{
  imports = [
    inputs.noctalia.homeModules.default
    ./cac.nix
  ];

  home.packages = with pkgs; [
    inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.default
    adw-gtk3
    glib
    wl-clipboard # system clipboard for Neovim under Wayland
  ];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = {
      shell.font = "JetBrainsMono Nerd Font";
      shell.screenshot.directory = "~/Pictures/Screenshots";
      wallpaper = {
        directory = "${../../wallpapers}"; # what the wallpaper picker shows
        default.path = "${wallpaper}";
      };
      theme = {
        mode = "dark";
        source = "custom";
        custom_palette = "MonokaiPro";
        templates = {
          enable_builtin_templates = true;
          builtin_ids = [
            "gtk3"
            "gtk4"
          ];
        };
      };
    };

    # Zed's Monokai Pro (Darker, Spectrum filter), same colors as Alacritty.
    # GTK apps and Hyprland borders follow it through Noctalia's templates.
    customPalettes.MonokaiPro.dark = {
      mPrimary = "#78a9ff"; # blue accent
      mOnPrimary = "#222222";
      mSecondary = "#5ad4e6"; # cyan
      mOnSecondary = "#222222";
      mTertiary = "#948ae3"; # purple
      mOnTertiary = "#222222";
      mError = "#fc618d";
      mOnError = "#222222";
      mSurface = "#222222"; # Zed editor background
      mOnSurface = "#f7f1ff";
      mSurfaceVariant = "#363537";
      mOnSurfaceVariant = "#8b888f";
      mOutline = "#69676c";
      mShadow = "#121212";
      mHover = "#403e41";
      mOnHover = "#f7f1ff";
      terminal = {
        background = "#222222";
        foreground = "#f7f1ff";
        cursor = "#f7f1ff";
        cursorText = "#222222";
        selectionBg = "#373637";
        selectionFg = "#f7f1ff";
        normal = {
          black = "#363537";
          red = "#fc618d";
          green = "#7bd88f";
          yellow = "#fce566";
          blue = "#fd9353";
          magenta = "#948ae3";
          cyan = "#5ad4e6";
          white = "#f7f1ff";
        };
        bright = {
          black = "#69676c";
          red = "#fc618d";
          green = "#7bd88f";
          yellow = "#fce566";
          blue = "#fd9353";
          magenta = "#948ae3";
          cyan = "#5ad4e6";
          white = "#f7f1ff";
        };
      };
    };
  };

  systemd.user.services.noctalia.Service.ExecStartPost = "${setWallpaper}";

  home.pointerCursor = {
    enable = true;
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
    hyprcursor.enable = true;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    package = null;
    portalPackage = null;
    systemd.enable = true;
    extraConfig = builtins.readFile ./hyprland.lua;
  };
}
