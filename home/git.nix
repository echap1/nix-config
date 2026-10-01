# Git identity and GitHub login. Shared by Linux and macOS.
# Log in once per machine with `gh auth login`; git then pushes to GitHub over HTTPS using that login.
{ ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Ethan Chapman";
        email = "ethan.chapman0@outlook.com";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };

  programs.gh = {
    enable = true;
    settings.git_protocol = "https";
    # Makes git use gh's login for github.com (on by default, stated for clarity)
    gitCredentialHelper.enable = true;
  };

  programs.git.includes = [
    {
      condition = "gitdir:~/src/";
      path = "~/.config/git/work";
    }
  ];
}
