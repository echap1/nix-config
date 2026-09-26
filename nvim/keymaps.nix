# Editor-wide keys. Where Zed's vim mode and Neovim disagree, this follows Zed.
# LSP keys live in lsp.nix, debugger keys in dap.nix.
#
# Ctrl+Shift combinations need a terminal that reports them (kitty, Alacritty, Ghostty,
# WezTerm, foot); each one also has a <Space> version that works everywhere.
{ lib, ... }:
let
  raw = lib.nixvim.mkRaw;
  pick = p: raw "function() Snacks.picker.${p}() end";
  n = key: action: desc: {
    mode = "n";
    inherit key action;
    options.desc = desc;
  };
in
{
  keymaps = [
    ## Zed workspace keys
    (n "<C-p>" (pick "files") "Find file")
    (n "<C-S-p>" (pick "commands") "Command palette")
    (n "<C-S-f>" (pick "grep") "Search project")
    (n "g/" (pick "grep") "Search project")
    (n "gs" (pick "lsp_symbols") "Symbols in file")
    (n "<C-S-o>" (pick "lsp_symbols") "Symbols in file")
    (n "gS" (pick "lsp_workspace_symbols") "Symbols in project")
    (n "<C-S-e>" (raw "function() Snacks.explorer() end") "File explorer")
    (n "<C-S-m>" "<Cmd>Trouble diagnostics toggle<CR>" "Diagnostics panel")
    (n "<C-S-b>" "<Cmd>Trouble symbols toggle focus=false win.position=left<CR>" "Outline panel")
    (n "<C-S-g>" (raw "function() Snacks.lazygit() end") "Git (lazygit)")
    (n "<C-S-i>" (raw "function() require('conform').format({ lsp_format = 'fallback' }) end") "Format")
    (n "<C-k><C-t>" (pick "colorschemes") "Theme picker")
    {
      mode = [
        "n"
        "t"
      ];
      key = "<C-`>";
      action = raw "function() Snacks.terminal.toggle() end";
      options.desc = "Terminal";
    }
    {
      mode = "n";
      key = "<C-/>";
      action = "gcc";
      options = {
        remap = true;
        desc = "Toggle comment";
      };
    }
    {
      mode = "x";
      key = "<C-/>";
      action = "gc";
      options = {
        remap = true;
        desc = "Toggle comment";
      };
    }
    {
      mode = "i";
      key = "<C-s>";
      action = raw "vim.lsp.buf.signature_help";
      options.desc = "Signature help";
    }

    ## Diagnostics (Zed: g] g[ as well as ]d [d)
    (n "g]" (raw "function() vim.diagnostic.jump({ count = 1, float = true }) end") "Next diagnostic")
    (n "g[" (raw "function() vim.diagnostic.jump({ count = -1, float = true }) end")
      "Previous diagnostic"
    )

    ## Git hunks (Zed: ]c [c, do, dO, dp)
    (n "]c"
      (raw "function() if vim.wo.diff then vim.cmd.normal({ ']c', bang = true }) else require('gitsigns').nav_hunk('next') end end")
      "Next change"
    )
    (n "[c"
      (raw "function() if vim.wo.diff then vim.cmd.normal({ '[c', bang = true }) else require('gitsigns').nav_hunk('prev') end end")
      "Previous change"
    )
    (n "do"
      (raw "function() if vim.wo.diff then vim.cmd.normal({ 'do', bang = true }) else require('gitsigns').preview_hunk_inline() end end")
      "Expand diff hunk"
    )
    (n "dO" (raw "function() require('gitsigns').stage_hunk() end") "Toggle staged")
    (n "dp"
      (raw "function() if vim.wo.diff then vim.cmd.normal({ 'dp', bang = true }) else require('gitsigns').reset_hunk() end end")
      "Restore change"
    )

    ## Space: a menu pops up after a moment (which-key)
    # Mostly Zed's Helix-mode space keys
    (n "<leader>f" (pick "files") "Find file")
    (n "<leader>b" (pick "buffers") "Open buffers")
    (n "<leader>/" (pick "grep") "Search project")
    (n "<leader>s" (pick "lsp_symbols") "Symbols in file")
    (n "<leader>S" (pick "lsp_workspace_symbols") "Symbols in project")
    (n "<leader>r" (raw "vim.lsp.buf.rename") "Rename")
    (n "<leader>a" (raw "vim.lsp.buf.code_action") "Code actions")
    (n "<leader>k" (raw "vim.lsp.buf.hover") "Hover")
    (n "<leader>:" (pick "commands") "Commands")
    (n "<leader>p" (pick "projects") "Recent projects")
    (n "<leader>o" (pick "recent") "Recent files")
    (n "<leader>?" (pick "keymaps") "Search keymaps")
    (n "<leader>e" (raw "function() Snacks.explorer() end") "File explorer")
    (n "<leader>g" (raw "function() Snacks.lazygit() end") "Git (lazygit)")
    (n "<leader>t" (raw "function() Snacks.terminal.toggle() end") "Terminal")
    (n "<leader>x" "<Cmd>Trouble diagnostics toggle<CR>" "Diagnostics panel")
    (n "<leader>q" (raw "function() Snacks.bufdelete() end") "Close buffer")
    (n "<leader>hb" (raw "function() require('gitsigns').blame_line({ full = true }) end") "Blame line")
    (n "<leader>hd" (raw "function() require('gitsigns').diffthis() end") "Diff file")

    ## Buffers as tabs (Zed: gt / gT move between tabs)
    (n "gt" "<Cmd>BufferLineCycleNext<CR>" "Next tab")
    (n "gT" "<Cmd>BufferLineCyclePrev<CR>" "Previous tab")

    ## Clear search highlight
    (n "<Esc>" "<Cmd>nohlsearch<CR><Esc>" "Clear highlight")
  ];
}
