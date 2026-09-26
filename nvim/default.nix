# Neovim (nixvim). A plain nixvim module: used by Home Manager in home/common.nix,
# and by `nix run .#nvim` on any machine.
#
# Keys follow Zed's vim mode and its default Linux keymap, so muscle memory carries over.
# Space is the leader for extras Zed doesn't have; press it and wait for a menu.
{ pkgs, ... }:
{
  imports = [
    ./keymaps.nix
    ./lsp.nix
    ./dap.nix
    ./ui.nix
    ./editing.nix
  ];

  globals = {
    mapleader = " ";
    maplocalleader = " ";
    # Filetype plugins (Python's, for one) map ]m, ]] and friends per buffer,
    # which would shadow the treesitter motions below
    no_plugin_maps = 1;
  };

  # Same look as Zed: Monokai Pro, Spectrum filter
  colorschemes.monokai-pro = {
    enable = true;
    settings.filter = "spectrum";
  };

  opts = {
    number = true;
    signcolumn = "yes";
    cursorline = true;
    scrolloff = 8;
    termguicolors = true;
    mouse = "a";

    expandtab = true;
    shiftwidth = 4;
    tabstop = 4;
    smartindent = true;

    ignorecase = true;
    smartcase = true;

    splitright = true;
    splitbelow = true;

    undofile = true;
    swapfile = false;
    updatetime = 250;
    timeoutlen = 400;

    # Zed's vim mode uses the system clipboard for yanks and puts
    clipboard = "unnamedplus";
  };

  # Zed autosaves 50 ms after an edit. This saves on leaving insert mode and on
  # normal-mode edits, without running format-on-save (:w still formats).
  autoGroups.autosave.clear = true;
  autoCmd = [
    {
      group = "autosave";
      event = [
        "InsertLeave"
        "TextChanged"
        "FocusLost"
        "BufLeave"
      ];
      callback.__raw = ''
        function(args)
          local buf = args.buf
          if vim.bo[buf].modified and vim.bo[buf].buftype == "" and vim.bo[buf].modifiable
            and vim.api.nvim_buf_get_name(buf) ~= "" then
            vim.api.nvim_buf_call(buf, function() vim.cmd("silent! noautocmd update") end)
          end
        end
      '';
    }
    {
      # Briefly highlight yanked text
      event = "TextYankPost";
      callback.__raw = "function() vim.hl.on_yank() end";
    }
  ];

  # Tools the plugins shell out to
  extraPackages = with pkgs; [
    ripgrep
    fd
    lazygit
    git
  ];
}
