# nix-config

```
flake.nix                  every machine is defined here
hosts/nixos/               NixOS laptop (system level)
hosts/darwin/              Mac (nix-darwin, system level)
home/common.nix            shared user setup: Neovim, Zed, Brave, Discord, CLI tools, font
home/fish.nix              fish shell (vi bindings, fzf, direnv)
home/alacritty.nix         Alacritty, Zed's Monokai colors
home/git.nix               git identity, gh (run `gh auth login` once per machine)
home/linux/                Hyprland, Noctalia, cursor, Linux-only apps
home/darwin/               Mac-only user setup, AeroSpace
home/zed/                  Zed settings + Monokai theme
nvim/                      Neovim (nixvim), also runnable on its own
certs/dod/                 DoD PKI certs for CAC (hosts/*/cac.nix, home/linux/cac.nix)
```

## Using it

| Where | Command |
|---|---|
| NixOS laptop | `sudo nixos-rebuild switch --flake ~/nix-config#nixos` |
| Mac, first time | `sudo nix run nix-darwin -- switch --flake ~/nix-config#mac` |
| Mac, afterwards | `sudo darwin-rebuild switch --flake ~/nix-config#mac` |
| Any other machine with Nix | `nix run home-manager -- switch --flake ~/nix-config#ethan@x86_64-linux` (or `@aarch64-linux`, `@aarch64-darwin`) |
| Just Neovim, nothing installed | `nix run ~/nix-config#nvim` (or `nix run github:<you>/<repo>#nvim` once it's pushed) |

Flakes only see files git knows about: `git add` new files before rebuilding.
Update everything with `nix flake update`, then rebuild.

Mac notes: the macOS account is assumed to be `ethan` (change `username` in `flake.nix`).
If Nix on the Mac came from the Determinate Systems installer, set `nix.enable = false`
in `hosts/darwin/configuration.nix`.

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
