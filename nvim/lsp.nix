# Language servers, completion, formatting and treesitter.
# Every server comes from nixpkgs, so there's no Mason and nothing to download.
{ lib, ... }:
{
  # Default server configs (cmd, filetypes, root markers) from nvim-lspconfig
  plugins.lspconfig.enable = true;

  lsp = {
    inlayHints.enable = true; # Zed: inlay_hints.enabled

    servers = {
      nixd.enable = true;
      rust_analyzer = {
        enable = true;
        # Same options as the Zed config
        config.settings.rust-analyzer = {
          cargo = {
            allTargets = false;
            features = [ ];
          };
          procMacro.enable = true;
          check.command = "clippy";
        };
      };
      clangd.enable = true;
      basedpyright.enable = true;
      ruff.enable = true;
      gopls.enable = true;
      lua_ls.enable = true;
      bashls.enable = true;
      jsonls.enable = true;
      yamlls.enable = true;
      taplo.enable = true;
      marksman.enable = true;
      ts_ls.enable = true;
    };

    # Zed vim-mode LSP keys, active in buffers with a server attached
    keymaps = [
      {
        key = "gd";
        lspBufAction = "definition";
        options.desc = "Go to definition";
      }
      {
        key = "<C-]>";
        lspBufAction = "definition";
        options.desc = "Go to definition";
      }
      {
        key = "gD";
        lspBufAction = "declaration";
        options.desc = "Go to declaration";
      }
      {
        key = "gy";
        lspBufAction = "type_definition";
        options.desc = "Go to type definition";
      }
      {
        key = "gI";
        action = lib.nixvim.mkRaw "function() Snacks.picker.lsp_implementations() end";
        options.desc = "Go to implementation";
      }
      {
        key = "gA";
        action = lib.nixvim.mkRaw "function() Snacks.picker.lsp_references() end";
        options.desc = "All references";
      }
      {
        key = "cd";
        lspBufAction = "rename";
        options.desc = "Rename symbol";
      }
      {
        key = "g.";
        mode = [
          "n"
          "x"
        ];
        lspBufAction = "code_action";
        options.desc = "Code actions";
      }
      {
        key = "gh";
        lspBufAction = "hover";
        options.desc = "Hover";
      }
      {
        key = "K";
        lspBufAction = "hover";
        options.desc = "Hover";
      }
      {
        key = "<C-w>gd";
        action = "<C-w>v<Cmd>lua vim.lsp.buf.definition()<CR>";
        options.desc = "Definition in split";
      }
      {
        key = "<C-w>gD";
        action = "<C-w>v<Cmd>lua vim.lsp.buf.type_definition()<CR>";
        options.desc = "Type definition in split";
      }
    ];
  };

  # Zed: diagnostics.inline.enabled
  diagnostic.settings = {
    virtual_text = {
      spacing = 2;
      prefix = "●";
    };
    severity_sort = true;
    float.border = "rounded";
    signs.text = lib.nixvim.mkRaw ''
      {
        [vim.diagnostic.severity.ERROR] = " ",
        [vim.diagnostic.severity.WARN] = " ",
        [vim.diagnostic.severity.INFO] = " ",
        [vim.diagnostic.severity.HINT] = "󰌵 ",
      }
    '';
  };

  # Completion
  plugins.blink-cmp = {
    enable = true;
    settings = {
      keymap.preset = "default"; # C-y accept, C-n/C-p move, C-space open, C-e close
      completion = {
        documentation.auto_show = true;
        ghost_text.enabled = false; # Zed: edit_predictions off
      };
      # Zed: auto_signature_help = false (C-k still shows it on demand)
      signature.enabled = true;
      signature.trigger.enabled = false;
      sources.default = [
        "lsp"
        "path"
        "snippets"
        "buffer"
      ];
    };
  };
  plugins.friendly-snippets.enable = true;

  # Format on :w (not on autosave), like Zed's format_on_save
  plugins.conform-nvim = {
    enable = true;
    autoInstall.enable = true; # pulls each formatter below from nixpkgs
    settings = {
      formatters_by_ft = {
        nix = [ "nixfmt" ];
        rust = [ "rustfmt" ];
        python = [
          "ruff_organize_imports"
          "ruff_format"
        ];
        lua = [ "stylua" ];
        go = [ "gofmt" ];
        sh = [ "shfmt" ];
        c = [ "clang-format" ];
        cpp = [ "clang-format" ];
        javascript = [ "prettier" ];
        typescript = [ "prettier" ];
        json = [ "prettier" ];
        yaml = [ "prettier" ];
        markdown = [ "prettier" ];
        toml = [ "taplo" ];
        "_" = [ "trim_whitespace" ];
      };
      default_format_opts.lsp_format = "fallback";
      format_on_save = {
        timeout_ms = 1000;
        lsp_format = "fallback";
      };
    };
  };

  plugins.treesitter = {
    enable = true;
    highlight.enable = true;
    indent.enable = true;
    folding.enable = true;
  };
  opts.foldlevel = 99; # start with everything unfolded

  # Neovim's own Lua API for lua_ls (handy for editing this config)
  plugins.lazydev.enable = true;
}
