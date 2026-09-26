# Pickers, panels, status line and git signs.
{ pkgs, ... }:
{
  plugins = {
    web-devicons.enable = true;

    # File finder, project search, explorer, terminal, lazygit, notifications
    snacks = {
      enable = true;
      settings = {
        picker.enabled = true;
        explorer.enabled = true; # Zed: project panel on the left
        terminal.enabled = true;
        lazygit.enabled = true;
        notifier.enabled = true;
        input.enabled = true;
        indent.enabled = true;
        words.enabled = true; # highlight other uses of the word under the cursor
        bigfile.enabled = true;
        quickfile.enabled = true;
        statuscolumn.enabled = true;
      };
    };

    # Diagnostics and outline panels
    trouble.enable = true;

    gitsigns = {
      enable = true;
      settings.current_line_blame = false;
    };

    # Buffers shown as tabs, like Zed's tab bar
    bufferline = {
      enable = true;
      settings.options = {
        diagnostics = "nvim_lsp";
        always_show_bufferline = true;
        offsets = [
          {
            filetype = "snacks_layout_box";
            text = "Explorer";
          }
        ];
      };
    };

    lualine = {
      enable = true;
      settings.options = {
        theme = "monokai-pro";
        globalstatus = true;
        component_separators = "";
        section_separators = "";
      };
    };

    which-key = {
      enable = true;
      settings = {
        preset = "helix";
        spec = [
          {
            __unkeyed-1 = "<leader>d";
            group = "debug";
          }
          {
            __unkeyed-1 = "<leader>h";
            group = "git hunk";
          }
        ];
      };
    };
  };

  # monokai-pro gives snacks' explorer and pickers three different backgrounds.
  # Use one panel color everywhere, Zed's #1c1c1c.
  highlightOverride =
    let
      panel = "#1c1c1c";
      text = "#f7f1ff";
      muted = "#8b888f";
      fill = fg: {
        inherit fg;
        bg = panel;
      };
    in
    {
      NormalFloat = fill text;
      FloatBorder = fill muted;
      FloatTitle = fill "#fce566";
      SnacksNormal = fill text;
      SnacksNormalNC = fill text;
      SnacksPicker = fill text;
      SnacksPickerBox = fill text;
      SnacksPickerList = fill text;
      SnacksPickerInput = fill text;
      SnacksPickerTree = fill "#403e41";
      SnacksPickerBorder = fill muted;
      SnacksPickerBoxBorder = fill muted;
      SnacksPickerInputBorder = fill muted;
      SnacksPickerTitle = fill "#fce566";
      SnacksPickerBoxTitle = fill "#fce566";
      SnacksPickerInputTitle = fill "#fce566";
      SnacksPickerListTitle = fill "#fce566";
      SnacksPickerPrompt = fill "#fd9353";
      SnacksPickerDir.fg = muted;
      SnacksPickerDirectory.fg = text;
      Directory.fg = text;
    };

  # System clipboard under Wayland; macOS uses pbcopy/pbpaste on its own
  clipboard.providers.wl-copy.enable = pkgs.stdenv.hostPlatform.isLinux;
}
