# The Windows side of a WSL machine (host feature "windows").
#
# Zed, Alacritty, GlazeWM and Zebar run as Windows apps, so Home Manager can't manage
# them the usual way, and Windows can't read config files out of the Nix store. Instead,
# every `home-manager switch` builds their configs from the same settings the Linux and
# Mac machines use and copies them into your Windows profile:
#
#   %APPDATA%\Zed\settings.json, keymap.json, themes\monokai.json   (home/zed/settings.nix)
#   %APPDATA%\alacritty\alacritty.toml                              (home/alacritty-settings.nix)
#   %USERPROFILE%\.glzr\glazewm\config.yaml                         (./glazewm.yaml)
#   %USERPROFILE%\.glzr\zebar\settings.json, monokai\               (./zebar)
#
# The apps themselves are installed with winget (README: "WSL on a Windows machine").
# A file that's about to be replaced for the first time is kept as <file>.before-nix.
{ lib, pkgs, ... }:
let
  zed = import ../zed/settings.nix { };
  json = pkgs.formats.json { };
  toml = pkgs.formats.toml { };

  zedSettings = json.generate "zed-settings.json" (
    zed.settings
    // {
      # Home Manager's `extensions` on the other machines does the same thing
      auto_install_extensions = lib.genAttrs zed.extensions (_: true);
    }
  );
  zedKeymap = json.generate "zed-keymap.json" zed.keymaps;

  alacritty = toml.generate "alacritty.toml" (
    lib.recursiveUpdate (import ../alacritty-settings.nix) {
      # Every Alacritty window opens your WSL shell (fish), in your Linux home folder
      terminal.shell = {
        program = "wsl.exe";
        args = [
          "--cd"
          "~"
        ];
      };
    }
  );

  jq = lib.getExe pkgs.jq;
  cmp = "${pkgs.diffutils}/bin/cmp";
in
{
  # Zed on Windows uses these when it opens a folder inside WSL
  home.packages = [
    pkgs.nixd
    pkgs.nixfmt
  ];

  home.activation.windowsConfigs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Ask Windows where your profile is (cmd.exe complains when started from a WSL folder)
    winenv() { (cd /mnt/c && /mnt/c/Windows/System32/cmd.exe /d /c "echo %$1%" 2>/dev/null) | tr -d '\r'; }
    appdata=$(winenv APPDATA)
    profile=$(winenv USERPROFILE)

    if [ -z "$appdata" ] || [ "$appdata" = "%APPDATA%" ] || [ -z "$profile" ]; then
      warnEcho "Couldn't reach Windows (is WSL interop on?); skipping the Windows app configs"
    else
      appdata=$(/usr/bin/wslpath -u "$appdata")
      profile=$(/usr/bin/wslpath -u "$profile")

      # put SOURCE DEST: copy, keeping the original the first time it's replaced
      put() {
        if [ -f "$2" ] && ! ${cmp} -s "$1" "$2" && [ ! -e "$2.before-nix" ]; then
          run cp "$2" "$2.before-nix"
        fi
        run mkdir -p "$(dirname "$2")"
        run cp --no-preserve=mode "$1" "$2"
      }

      # Zed: like on the other machines, settings.json stays writable. Changes made in
      # Zed's UI are kept, and these settings are merged on top. (A file with comments
      # can't be merged; it's kept as settings.json.before-nix and replaced.)
      zedFile="$appdata/Zed/settings.json"
      if [ -f "$zedFile" ] && merged=$(${jq} -s '.[0] * .[1]' "$zedFile" ${zedSettings} 2>/dev/null); then
        tmp=$(mktemp)
        printf '%s\n' "$merged" >"$tmp"
        put "$tmp" "$zedFile"
        rm -f "$tmp"
      else
        put ${zedSettings} "$zedFile"
      fi
      put ${zedKeymap} "$appdata/Zed/keymap.json"
      put ${../zed/monokai.json} "$appdata/Zed/themes/monokai.json"

      put ${alacritty} "$appdata/alacritty/alacritty.toml"

      put ${./glazewm.yaml} "$profile/.glzr/glazewm/config.yaml"
      put ${./zebar/settings.json} "$profile/.glzr/zebar/settings.json"
      for f in ${./zebar/monokai}/*; do
        put "$f" "$profile/.glzr/zebar/monokai/$(basename "$f")"
      done

      verboseEcho "Windows app configs copied to $profile"
    fi
  '';
}
