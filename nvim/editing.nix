# Text editing extras that Zed's vim mode has built in.
{ lib, ... }:
let
  raw = lib.nixvim.mkRaw;
  select = obj: {
    mode = [
      "x"
      "o"
    ];
    key = obj.key;
    action = raw "function() require('nvim-treesitter-textobjects.select').select_textobject('${obj.query}', 'textobjects') end";
    options.desc = obj.desc;
  };
  move = key: fn: query: desc: {
    mode = [
      "n"
      "x"
      "o"
    ];
    inherit key;
    action = raw "function() require('nvim-treesitter-textobjects.move').${fn}('${query}', 'textobjects') end";
    options.desc = desc;
  };
  mc = key: fn: desc: {
    mode = [
      "n"
      "x"
    ];
    inherit key;
    action = raw "function() require('multicursor-nvim').${fn} end";
    options.desc = desc;
  };
in
{
  plugins = {
    # ys / cs / ds surround, same keys as Zed
    nvim-surround.enable = true;

    # Zed closes brackets and quotes as you type
    mini-pairs.enable = true;

    # Zed's gR (replace with register) and cx (exchange)
    mini-operators = {
      enable = true;
      settings = {
        replace.prefix = "gR";
        exchange.prefix = "cx";
        evaluate.prefix = "";
        multiply.prefix = "";
        sort.prefix = "";
      };
    };

    # Function / class / argument text objects and motions
    treesitter-textobjects = {
      enable = true;
      settings = {
        select.lookahead = true;
        move.set_jumps = true;
      };
    };

    # Zed multi-cursor: gl / gL add the next / previous match, ga adds all
    multicursor.enable = true;

    todo-comments.enable = true;
  };

  keymaps = [
    # Zed: af/if function, ac/ic class, aa/ia argument
    (select {
      key = "af";
      query = "@function.outer";
      desc = "around function";
    })
    (select {
      key = "if";
      query = "@function.inner";
      desc = "inside function";
    })
    (select {
      key = "ac";
      query = "@class.outer";
      desc = "around class";
    })
    (select {
      key = "ic";
      query = "@class.inner";
      desc = "inside class";
    })
    (select {
      key = "aa";
      query = "@parameter.outer";
      desc = "around argument";
    })
    (select {
      key = "ia";
      query = "@parameter.inner";
      desc = "inside argument";
    })

    # Zed: ]m [m method, ]M [M method end, ]] [[ section
    (move "]m" "goto_next_start" "@function.outer" "Next method")
    (move "[m" "goto_previous_start" "@function.outer" "Previous method")
    (move "]M" "goto_next_end" "@function.outer" "Next method end")
    (move "[M" "goto_previous_end" "@function.outer" "Previous method end")
    (move "]]" "goto_next_start" "@class.outer" "Next section")
    (move "[[" "goto_previous_start" "@class.outer" "Previous section")
    (move "]/" "goto_next_start" "@comment.outer" "Next comment")
    (move "[/" "goto_previous_start" "@comment.outer" "Previous comment")

    # Multi-cursor
    (mc "gl" "matchAddCursor(1)" "Add cursor at next match")
    (mc "gL" "matchAddCursor(-1)" "Add cursor at previous match")
    (mc "ga" "matchAllAddCursors()" "Add cursors at all matches")
    (mc "g>" "matchSkipCursor(1)" "Skip, add next match")
    (mc "g<" "matchSkipCursor(-1)" "Skip, add previous match")
  ];

  # While there are several cursors: Esc clears them
  extraConfigLua = ''
    local mc = require("multicursor-nvim")
    mc.addKeymapLayer(function(layer)
      layer("n", "<Esc>", function()
        if not mc.cursorsEnabled() then mc.enableCursors() else mc.clearCursors() end
      end)
    end)
  '';
}
