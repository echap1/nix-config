# nix-config

Every machine I use, set up from this repo: NixOS laptops and servers, Macs, and
Home Manager on anything else (WSL, other distros). A new machine takes one command
plus a few logins.

## Set up a new machine

Every path ends in the same dialog, `nix run .#provision`, which asks for a name,
**Desktop** or **Command line only**, and extras (**tailscale**, **cac**), writes
`hosts/<name>/` and switches to it.

### A Mac

1. Install Nix: `curl -fsSL https://install.determinate.systems/nix | sh -s -- install`
   (the provision script notices it's Determinate and adjusts).
2. `git clone https://github.com/<you>/nix-config ~/nix-config && cd ~/nix-config`
3. `nix run .#provision` → **Set up this machine**.

Homebrew is installed for you (for Claude, Bitwarden and Tailscale). Apps you had
installed before are left alone; uninstall duplicates of what this config installs.

### NixOS on a machine you're sitting at (already installed)

1. On the fresh install: `nix-shell -p git --run "git clone https://github.com/<you>/nix-config ~/nix-config"`
2. `cd ~/nix-config && nix --extra-experimental-features "nix-command flakes" run .#provision`
   → **Set up this machine**. It saves the hardware config and switches.

### NixOS on another machine, over the network (erases it)

For a new laptop, desktop or server. Run from a machine that already has this repo.

1. Boot the target from the [NixOS installer](https://nixos.org/download) USB.
2. On it: `passwd` (temporary root password) and `ip addr` (its address).
3. Here: `nix run .#provision` → **Install NixOS on another machine**. Pick the disk,
   Desktop or Command line, extras, and whether to encrypt the disk.

It also asks for your login password; only its hash is copied onto the machine (never
into the repo), and it's set on first boot. nixos-anywhere partitions the disk (disko:
Btrfs, optional LUKS), installs the whole configuration, and reboots into it.

### Any other Linux (or WSL without the Windows apps)

1. Install Nix: `curl -fsSL https://install.determinate.systems/nix | sh -s -- install`
2. Clone as above, then `nix run .#provision` → **Set up this machine** → usually
   **Command line only**. It also offers to make fish your login shell.

### WSL on a Windows machine (with Zed, Alacritty, GlazeWM and Zebar)

The command line (fish, Neovim, git, ...) lives in WSL and is managed by Home Manager
like any other Linux. The desktop apps are Windows apps: they're installed with winget,
and the `windows` host feature (`home/windows/`) writes their configs, built from the
same settings as the other machines, into your Windows profile on every switch.

**In Windows** (PowerShell):

```powershell
winget install ZedIndustries.Zed Alacritty.Alacritty glzr-io.glazewm glzr-io.zebar Microsoft.PowerToys Brave.Brave
winget install DEVCOM.JetBrainsMonoNerdFont
```

Windows 11 is needed for GlazeWM's colored borders and rounded corners.

**In WSL:**

1. Turn on systemd: add `[boot]` / `systemd=true` to `/etc/wsl.conf`, then run
   `wsl --shutdown` from Windows and reopen the WSL terminal.
2. Install Nix: `curl -fsSL https://install.determinate.systems/nix | sh -s -- install`
3. Clone the repo into your Linux home (`~/nix-config`, not under `/mnt/c`), then
   `nix run .#provision` → **Set up this machine** → **Command line only** → say yes to
   *Also set up Zed, Alacritty, GlazeWM and Zebar on the Windows side?* (It adds
   `features = [ "windows" ];` to `hosts/<name>/host.nix`.)

Every `home-manager switch --flake ~/nix-config#<name>` then copies:

| App | Goes to | Built from |
|---|---|---|
| Zed | `%APPDATA%\Zed\` settings, keymap, Monokai theme | `home/zed/settings.nix` |
| Alacritty | `%APPDATA%\alacritty\alacritty.toml` (opens WSL) | `home/alacritty-settings.nix` |
| GlazeWM | `%USERPROFILE%\.glzr\glazewm\config.yaml` | `home/windows/glazewm.yaml` |
| Zebar | `%USERPROFILE%\.glzr\zebar\` (the `monokai` bar) | `home/windows/zebar/` |

The first time a file is replaced, the old one is kept next to it as `*.before-nix`.
Zed's settings.json stays writable like on the other machines: changes from Zed's UI
are kept and these settings are merged on top.

**Then, once:**

- Start GlazeWM (it starts Zebar) and have it run at sign-in (its tray icon menu, or a
  shortcut in `shell:startup`). After a later switch, `Alt+Shift+R` reloads GlazeWM; for
  bar changes, quit Zebar from its tray icon and start it again.
- **App launcher:** open PowerToys, turn on *PowerToys Run*, which opens with `Alt+Space`,
  the same key as the Noctalia launcher. (Or use *Command Palette* and set its shortcut
  to `Alt+Space`.) GlazeWM leaves `Alt+Space` free for it.
- **Zed:** open Linux projects with *File → Open Remote → WSL* (or `zed .` inside WSL), so
  language servers and `nixd` run in WSL next to your code.

GlazeWM keys are the Hyprland ones with `Alt` in place of `Super` (Windows keeps most
`Win` combinations for itself), the same as AeroSpace on the Mac:

| Keys | Does |
|---|---|
| `Alt h/j/k/l` / `Alt+Shift h/j/k/l` | focus / move window |
| `Alt 1-0` / `Alt+Shift 1-0` / `Alt+Ctrl 1-0` | workspace / move window and follow / send window |
| `Alt+Ctrl h/l` (add `Shift` to take the window) | previous / next workspace |
| `Alt S` / `Alt+Shift S` | scratch workspace / send window there |
| `Alt Enter` / `Alt W` / `Alt E` | Alacritty / Brave / Explorer |
| `Alt Q` / `Alt F` / `Alt D` | close / fullscreen / maximize |
| `Alt+Shift Space` / `Alt /` / `Alt =` `Alt -` | float / split direction / resize |
| `Alt+Shift Tab` | move workspace to next monitor |
| `Alt+Shift R` / `Alt+Shift P` / `Alt+Shift E` | reload / pause (games, RDP) / quit GlazeWM |
| `Alt Space` | app launcher (PowerToys) |

Windows' own keys cover the rest of Noctalia: `Win+V` clipboard, `Win+.` emoji,
`Win+Shift+S` screenshot, `Win+L` lock.

### Just the editor

`nix run github:<you>/nix-config#nvim` runs this Neovim on any machine with Nix,
without installing anything (needs the repo to be public, or `gh auth login` first).

### After any new machine: the logins only you can do

- **Bitwarden:** log in, then turn on *Unlock with system authentication* (Linux) or
  *Unlock with Touch ID* (Mac) and *Allow browser integration*. In the Brave
  extension: *Account security → Unlock with biometrics*. After that, restarting or
  logging out only needs your system password or Touch ID, not the master password.
- **Brave:** Settings → Sync → *I have a sync code* for bookmarks, history and tabs.
  Keep the sync code in Bitwarden.
- **Tailscale:** `sudo tailscale up` (Linux) or the menu bar (Mac).
- **GitHub:** `gh auth login`.

Then commit the new `hosts/<name>/` and push.

## Day to day

| Do | Command |
|---|---|
| Apply changes (NixOS) | `sudo nixos-rebuild switch --flake ~/nix-config` |
| Apply changes (Mac) | `sudo darwin-rebuild switch --flake ~/nix-config` |
| Apply changes (other) | `home-manager switch --flake ~/nix-config#<name>` |
| Update everything | `nix flake update`, then apply |
| Tools for this repo | `nix develop` |

Flakes only see files git knows about: `git add` new files before applying. Old
generations are cleaned up weekly on NixOS.

## Tailscale: reach every machine from anywhere

1. Make an account at [tailscale.com](https://login.tailscale.com/start). Sign up with a
   passkey to use your YubiKey.
2. Admin console → **Access controls**: replace the policy with this. It allows traffic
   between your devices, file sharing (Taildrive), and Tailscale SSH to your own devices
   (`check` asks you to confirm in the browser now and then; `accept` doesn't):

   ```json
   {
     "grants": [
       { "src": ["*"], "dst": ["*"], "ip": ["*"] },
       { "src": ["*"], "dst": ["*"],
         "app": { "tailscale.com/cap/drive": [{ "shares": ["*"], "access": "rw" }] } }
     ],
     "nodeAttrs": [
       { "target": ["autogroup:member"], "attr": ["drive:share", "drive:access"] }
     ],
     "ssh": [
       { "action": "check", "src": ["autogroup:member"], "dst": ["autogroup:self"],
         "users": ["autogroup:nonroot", "root"] }
     ]
   }
   ```

3. Put each machine's SSH public key in `keys/` (`ssh-keygen -t ed25519`, then copy
   `~/.ssh/id_ed25519.pub` to `keys/<machine>.pub`) and apply on the Macs. NixOS
   machines don't need it (Tailscale SSH), but the Mac's Remote Login is key-only.

Then, from any of your machines:

- **Terminal:** `ssh <machine>`. NixOS machines answer with Tailscale SSH (no keys);
  Macs with Remote Login, using the keys in `keys/`.
- **Files, Linux:** Nautilus → *Other Locations* → `sftp://<machine>/home/ethan`, or
  `dav://100.100.100.100:8080` for every machine's shared home folder (Taildrive).
- **Files, Mac:** Finder → *Go → Connect to Server* (Cmd-K) → `http://100.100.100.100:8080`,
  connect as Guest. To share the Mac's own folders, add them in the Tailscale menu bar
  app under *Taildrive*.
- **Editor:** Zed's *Open Remote* with `ssh <machine>` edits files on another machine.

NixOS machines only accept SSH over Tailscale; nothing is exposed on other networks.

## Layout

```
flake.nix                 inputs and outputs
lib/default.nix           turns every hosts/<name>/host.nix into a machine
hosts/<name>/host.nix     kind (nixos / darwin / home), system, gui, features
hosts/<name>/default.nix  what's specific to that machine (boot loader, hardware, disk)
modules/nixos/            shared NixOS: base, desktop (gui), tailscale, cac
modules/darwin/           shared macOS: settings, Homebrew apps, cac
modules/disko/            disk layout for nixos-anywhere installs
home/core.nix             every machine: Neovim, fish, git, CLI tools
home/gui.nix              desktops: Zed, Alacritty, Brave, Discord, Obsidian
home/zed/settings.nix     Zed settings, shared by home/zed and home/windows
home/alacritty-settings.nix  Alacritty settings, shared the same way
home/linux/               Linux desktop: Hyprland, Noctalia, cursor, CAC in Brave
home/darwin/              Mac: AeroSpace, wallpaper
home/windows/             WSL's Windows side: GlazeWM, Zebar, and copies of the above
nvim/                     Neovim (nixvim), also runnable on its own
certs/dod/                DoD PKI certificates for CAC
keys/                     SSH public keys allowed to log in (e.g. YubiKey)
scripts/provision.sh      the setup dialog
```

To add a feature, create a module and turn it on from `host.nix` `features`
(see how `tailscale` and `cac` are wired in `modules/nixos/default.nix`, and `windows`
in `lib/default.nix`).

## Neovim keys

Zed vim-mode keys work the same. Press Space and wait for a menu of the rest.

| Keys | Does |
|---|---|
| `Ctrl-p` / `Space f` | find file |
| `Ctrl-Shift-p` | command palette |
| `Ctrl-Shift-f` / `g/` / `Space /` | search project |
| `gs` / `gS` | symbols in file / in project |
| `gd` `gD` `gy` `gI` `gA` | definition, declaration, type, implementation, all references |
| `K` / `gh` | hover |
| `cd` | rename |
| `g.` | code actions |
| `]d` `[d` / `g]` `g[` | next / previous diagnostic |
| `]c` `[c` | next / previous git change |
| `do` `dO` `dp` | show hunk, stage/unstage hunk, restore hunk |
| `af` `if` `ac` `ic` `aa` `ia` | function / class / argument text objects |
| `]m` `[m` `]]` `[[` | next / previous function, class |
| `gl` `gL` `ga` | multi-cursor: next match, previous match, all matches (`Esc` clears) |
| `ys` `cs` `ds` | surround |
| `gR` / `cx` | replace with register / exchange |
| `Ctrl-/` | toggle comment |
| `Ctrl-Shift-e` / `Space e` | file explorer |
| `Ctrl-Shift-m` / `Space x` | diagnostics panel |
| `Ctrl-Shift-g` / `Space g` | lazygit |
| `` Ctrl-` `` / `Space t` | terminal |
| `gt` `gT` / `Space b` | next / previous tab, list buffers |

Debugger (Zed's keys, with `Space d…` versions):

| Keys | Does |
|---|---|
| `F4` / `F5` | start / continue |
| `Shift-F5` | stop |
| `Ctrl-Shift-F5` | restart |
| `F9` | toggle breakpoint |
| `F10` / `F11` / `Shift-F11` | step over / into / out |
| `Ctrl-Shift-d` / `Space du` | toggle debugger panels |
| `Space de` | evaluate expression |

Rust, C and C++ debug through CodeLLDB, Python through debugpy, Go through delve.
Project launch configs go in `.vscode/launch.json`.

Files autosave like Zed (on leaving insert mode and on edits). Formatting runs on `:w`.
