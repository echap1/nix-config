# Fish with vi key bindings. Shared by Linux and macOS.
{ ... }:
{
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set -g fish_greeting # no welcome message

      # fastfetch once per Alacritty window. The exported marker stops it from
      # showing again in shells started inside that window (nix-shell, nvim's terminal).
      if set -q ALACRITTY_WINDOW_ID; and not set -q __fastfetch_shown
        set -gx __fastfetch_shown 1
        fastfetch
      end

      fish_vi_key_bindings
      # Block cursor in normal mode, line in insert, underline in replace
      set -g fish_cursor_default block
      set -g fish_cursor_insert line
      set -g fish_cursor_replace_one underscore
      set -g fish_cursor_visual block

      # In insert mode, Ctrl-f accepts the grey autosuggestion (like the default emacs mode)
      bind -M insert ctrl-f accept-autosuggestion
    '';

    shellAbbrs = {
      g = "git";
      gs = "git status";
      gd = "git diff";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      ll = "ls -lh";
      la = "ls -lAh";
      v = "nvim";
    };
  };

  programs.fastfetch.enable = true;

  # nix-shell and nix develop drop you into fish instead of bash
  programs.nix-your-shell = {
    enable = true;
    enableFishIntegration = true;
  };

  # Ctrl-r history search, Ctrl-t file search, Alt-c cd into a folder
  programs.fzf.enable = true;

  # Loads a project's Nix dev shell automatically when you cd into it (needs a .envrc)
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
