# Zed settings, shared by home/zed (Zed installed by Nix on Linux and macOS) and
# home/windows (Zed installed natively on Windows, configured from WSL).
#
# nixd / nixfmt: absolute paths when Zed runs where Nix is. On Windows they're left
# out, and Zed finds nixd and nixfmt on the PATH inside WSL when you open a WSL folder.
{
  nixd ? null,
  nixfmt ? null,
}:
{
  # Installed by Zed on first launch
  extensions = [
    "material-icon-theme"
    "nix"
  ];

  # Ctrl-w h/j/k/l moves focus out of the terminal, like Vim's window keys
  keymaps = [
    {
      context = "Terminal";
      bindings = {
        "ctrl-w h" = "workspace::ActivatePaneLeft";
        "ctrl-w j" = "workspace::ActivatePaneDown";
        "ctrl-w k" = "workspace::ActivatePaneUp";
        "ctrl-w l" = "workspace::ActivatePaneRight";
      };
    }
  ];

  settings = {
    theme = "monokai Darker (Filter Spectrum)";
    icon_theme = "Material Icon Theme";

    buffer_font_family = "JetBrainsMono Nerd Font";
    ui_font_family = "JetBrainsMono Nerd Font";
    buffer_font_size = 13;
    ui_font_size = 14;

    vim_mode = true;
    autosave.after_delay.milliseconds = 50;
    auto_signature_help = false;

    project_panel.dock = "left";
    outline_panel.dock = "left";
    collaboration_panel.dock = "left";
    git_panel = {
      dock = "left";
      tree_view = true;
    };

    edit_predictions.provider = "none";

    agent = {
      dock = "right";
      tool_permissions.tools.terminal.default = "allow";
      default_model = {
        provider = "zed.dev";
        model = "claude-opus-4-6";
        effort = "high";
        enable_thinking = true;
      };
    };

    inlay_hints = {
      enabled = true;
      show_type_hints = true;
      show_parameter_hints = true;
    };

    diagnostics.inline.enabled = true;

    # Nix: use nixd from nixpkgs (a downloaded one wouldn't match your Nix)
    # and skip nil, which the extension would otherwise try to download.
    languages.Nix.language_servers = [
      "nixd"
      "!nil"
    ];

    lsp = {
      nixd =
        if nixd != null then
          {
            binary.path = nixd;
            settings.formatting.command = [ nixfmt ];
          }
        else
          { settings.formatting.command = [ "nixfmt" ]; };

      rust-analyzer.initialization_options = {
        cargo = {
          allTargets = false;
          features = [ ];
        };
        procMacro.enable = true;
        check.command = "clippy";
      };
    };
  };
}
