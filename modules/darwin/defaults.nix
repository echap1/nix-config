# macOS settings. Applied on every switch; some need a log out to take effect.
{
  system.defaults = {
    dock.autohide = true;

    NSGlobalDomain = {
      # Fast key repeat: 30 ms between repeats, 225 ms before repeating starts
      # (the fastest the Keyboard settings sliders allow)
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      # Holding a key repeats it instead of popping up the accent menu (needed for hjkl in vim)
      ApplePressAndHoldEnabled = false;
      AppleShowAllExtensions = true;
    };

    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true; # hidden files
    };
  };
}
