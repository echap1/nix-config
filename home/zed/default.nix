# Zed, ported from the Mac config. Shared by Linux and macOS.
{ pkgs, lib, ... }:
{
  programs.zed-editor = {
    enable = true;

    # Installed by Zed on first launch
    extensions = [
      "material-icon-theme"
      "nix"
      "lua"
      "dockerfile"
      "toml"
    ];

    # Monokai Pro theme pack (billgo/monokai)
    themes.monokai = ./monokai.json;

    # settings.json stays writable. Zed's own UI changes survive, and on each
    # rebuild these values are merged back in and take precedence.
    userSettings = {
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
        # Absolute paths so Zed finds them no matter what PATH it sees.
        # Other language servers are downloaded by Zed as usual (nix-ld handles that on NixOS).
        nixd = {
          binary.path = lib.getExe pkgs.nixd;
          settings.formatting.command = [ (lib.getExe pkgs.nixfmt) ];
        };

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
  };
}
