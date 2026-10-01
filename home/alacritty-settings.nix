# Alacritty settings with the same colors and font as Zed (Monokai Pro Darker, Spectrum
# filter; colors taken from home/zed/monokai.json). Used by home/alacritty.nix (Linux,
# macOS) and home/windows (Alacritty on Windows).
{
  font = {
    normal.family = "JetBrainsMono Nerd Font";
    size = 11;
  };

  window = {
    padding = {
      x = 8;
      y = 8;
    };
    opacity = 1.0;
  };

  colors = {
    primary = {
      background = "#222222";
      foreground = "#f7f1ff";
    };
    cursor = {
      text = "#222222";
      cursor = "#f7f1ff";
    };
    selection = {
      text = "CellForeground";
      background = "#373637"; # Zed: #f7f1ff at 10% over the background
    };
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
}
