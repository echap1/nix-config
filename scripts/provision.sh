# Set up a machine from this repo. Run with: nix run .#provision
#
#   This machine            adds hosts/<name>/ for the computer you're on and switches to it
#                           (NixOS, macOS, or any other Linux / WSL via Home Manager)
#   Another machine         wipes a machine booted from the NixOS installer and installs
#                           onto it over SSH (nixos-anywhere + disko)
#   Secrets                 sets up sops with your YubiKey: login password, Tailscale key
#
# Everything it writes is git-added; commit and push when you're happy.

USERNAME=ethan

say() { gum style --foreground 111 "$*"; }
warn() { gum style --foreground 214 "! $*"; }
die() {
  gum style --foreground 203 "✗ $*"
  exit 1
}
header() { gum style --border rounded --padding "0 2" --border-foreground 111 --bold "$@"; }

# ── Find (or fetch) the repo ─────────────────────────────────────────────────────
find_repo() {
  local top
  if top=$(git rev-parse --show-toplevel 2>/dev/null) && [ -f "$top/lib/default.nix" ]; then
    echo "$top"
  elif [ -f "$HOME/nix-config/lib/default.nix" ]; then
    echo "$HOME/nix-config"
  else
    local url
    url=$(gum input --header "Repo to clone into ~/nix-config" --placeholder "https://github.com/<you>/nix-config")
    [ -n "$url" ] || die "No repo given"
    git clone "$url" "$HOME/nix-config" >&2
    echo "$HOME/nix-config"
  fi
}

REPO=$(find_repo)
cd "$REPO"

# A `sudo nixos-rebuild` that updates flake.lock can leave root-owned files in .git,
# which breaks the `git add`s below (and nixos-anywhere's). Catch it up front.
if [ -n "$(find .git -not -user "$(id -u)" -print -quit 2>/dev/null)" ]; then
  die "Some files in $REPO/.git are owned by another user. Fix with: sudo chown -R $(id -un) $REPO"
fi

# Temp dirs, cleaned up on exit (globals so the exit trap can still see them)
TMP_EXTRA=""
TMP_KEYS=""
cleanup() { rm -rf "${TMP_EXTRA:-}" "${TMP_KEYS:-}"; }
trap cleanup EXIT

# sops looks for age identities (including YubiKey ones) here
if [ "$(uname -s)" = Darwin ]; then
  AGE_KEYS="$HOME/Library/Application Support/sops/age/keys.txt"
else
  AGE_KEYS="${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt"
fi
export SOPS_AGE_KEY_FILE="$AGE_KEYS"

# ── Small helpers ────────────────────────────────────────────────────────────────
valid_name() { [[ "$1" =~ ^[a-z0-9][a-z0-9-]*$ ]]; }

ask_name() {
  local suggestion=$1 name
  while true; do
    name=$(gum input --header "Machine name (lowercase, also its hostname and Tailscale name)" --value "$suggestion")
    if ! valid_name "$name"; then
      warn "Use lowercase letters, digits and dashes"
    elif [ -e "hosts/$name" ] && [ "${2:-}" != allow-existing ]; then
      warn "hosts/$name already exists"
    else
      echo "$name"
      return
    fi
  done
}

ask_gui() {
  local default=$1
  local choice
  choice=$(gum choose --header "What kind of setup?" --selected "$default" \
    "Desktop (apps, window manager)" "Command line only (server, WSL)")
  [[ "$choice" == Desktop* ]] && echo true || echo false
}

ask_features() {
  gum choose --no-limit --header "Extras (space to select, enter to continue)" \
    --selected "tailscale" "tailscale" "cac" | tr '\n' ' '
}

write_host_nix() {
  local dir=$1 kind=$2 system=$3 gui=$4 features=$5 f list=""
  for f in $features; do list+="\"$f\" "; done
  mkdir -p "$dir"
  cat >"$dir/host.nix" <<EOF
# Written by nix run .#provision. See lib/default.nix for what these mean.
{
  kind = "$kind";
  system = "$system";
  gui = $gui;
  features = [ $list];
}
EOF
}

nix_system() {
  local arch os
  arch=$(uname -m)
  os=$(uname -s)
  [ "$arch" = arm64 ] && arch=aarch64
  if [ "$os" = Darwin ]; then echo "$arch-darwin"; else echo "$arch-linux"; fi
}

age_recipient_add() { # recipient, comment
  R="$1" C="$2" yq -i '
    .creation_rules[0].key_groups[0].age += [strenv(R)] |
    (.creation_rules[0].key_groups[0].age[] | select(. == strenv(R))) line_comment = strenv(C)
  ' .sops.yaml
}

age_recipient_known() { R="$1" yq -e '.creation_rules[0].key_groups[0].age[] | select(. == strenv(R))' .sops.yaml >/dev/null 2>&1; }

# Give a machine's SSH host key access to the secrets (re-encrypts them; touch your YubiKey)
authorize_host_key() { # pubkey file, host name
  [ -f .sops.yaml ] || return 0
  local recipient
  recipient=$(ssh-to-age <"$1")
  if ! age_recipient_known "$recipient"; then
    # Drop a previous key for the same machine (e.g. after reinstalling it)
    C="host: $2" yq -i 'del(.creation_rules[0].key_groups[0].age[] | select(line_comment == strenv(C)))' .sops.yaml
    age_recipient_add "$recipient" "host: $2"
    say "Re-encrypting secrets for $2 (touch your YubiKey if it blinks)"
    for f in secrets/*.yaml; do [ -e "$f" ] && sops updatekeys -y "$f"; done
  fi
  git add .sops.yaml secrets
}

checklist() {
  header "Almost done: things only you can do (once per machine)"
  cat <<'EOF'
  • Bitwarden: log in, then Settings → turn on "Unlock with system authentication" (Linux)
    or "Unlock with Touch ID" (Mac), and "Allow browser integration".
    In Brave's Bitwarden extension: Settings → Account security → "Unlock with biometrics".
  • Brave: Settings → Sync → "I have a sync code" (keep the code in Bitwarden) for bookmarks,
    passwords off, history and tabs.
  • Tailscale: `sudo tailscale up` (Linux) or sign in from the menu bar (Mac).
  • GitHub: `gh auth login`.
  • Commit and push: git commit -m "Add <machine>" && git push
EOF
}

# ── This machine ─────────────────────────────────────────────────────────────────
setup_this_machine() {
  local os kind system name gui features default_gui
  os=$(uname -s)
  system=$(nix_system)
  if [ "$os" = Darwin ]; then
    kind=darwin
  elif [ -e /etc/NIXOS ]; then
    kind=nixos
  else
    kind=home
  fi

  [ "$(whoami)" = "$USERNAME" ] || warn "You're logged in as $(whoami), but this repo is set up for $USERNAME (change it in lib/default.nix)."

  local suggestion
  suggestion=$(hostname -s 2>/dev/null | tr '[:upper:]_' '[:lower:]-' | tr -cd 'a-z0-9-')
  if grep -qi microsoft /proc/version 2>/dev/null; then suggestion=wsl; fi

  if [ -n "$suggestion" ] && [ -f "hosts/$suggestion/host.nix" ] && gum confirm "hosts/$suggestion already exists. Apply it to this machine?"; then
    name=$suggestion
  else
    name=$(ask_name "$suggestion")
    default_gui="Desktop (apps, window manager)"
    if [ "$suggestion" = wsl ] || [ "$kind" = home ]; then default_gui="Command line only (server, WSL)"; fi
    gui=$(ask_gui "$default_gui")
    features=""
    [ "$kind" = home ] || features=$(ask_features)
    write_host_nix "hosts/$name" "$kind" "$system" "$gui" "$features"

    case $kind in
    nixos)
      say "Saving this machine's hardware config"
      nixos-generate-config --show-hardware-config >"hosts/$name/hardware-configuration.nix"
      local state boot
      state=$(sed -n 's/.*system.stateVersion *= *"\([0-9.]*\)".*/\1/p' /etc/nixos/configuration.nix 2>/dev/null | head -1)
      [ -n "$state" ] || state=$(nixos-version | cut -c1-5)
      if [ -d /sys/firmware/efi ]; then
        boot='boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;'
      else
        local disk
        disk=$(gum input --header "Legacy BIOS boot: disk to install GRUB on" --value /dev/sda)
        boot="boot.loader.grub.enable = true;
  boot.loader.grub.device = \"$disk\";"
      fi
      cat >"hosts/$name/default.nix" <<EOF
# Things specific to $name. Everything shared is in modules/nixos.
{ ... }:
{
  imports = [ ./hardware-configuration.nix ];

  $boot

  # The NixOS release this machine was first installed with; don't change it.
  system.stateVersion = "$state";
}
EOF
      ;;
    darwin)
      local nix_enable=true
      # The Determinate Systems installer manages Nix itself
      if [ -e /nix/receipt.json ] || [ -e /usr/local/bin/determinate-nixd ]; then nix_enable=false; fi
      cat >"hosts/$name/default.nix" <<EOF
# Things specific to $name. Everything shared is in modules/darwin.
{ username, ... }:
{
  # Your account's user ID (\`id -u\`); nix-darwin needs it to manage your login shell
  users.users.\${username}.uid = $(id -u);

  # false when Nix came from the Determinate Systems installer (it manages Nix itself)
  nix.enable = $nix_enable;

  # Set once at first switch; don't change it afterwards.
  system.stateVersion = 6;
}
EOF
      ;;
    esac
  fi
  git add "hosts/$name"

  case $kind in
  nixos)
    [ -f /etc/ssh/ssh_host_ed25519_key.pub ] && authorize_host_key /etc/ssh/ssh_host_ed25519_key.pub "$name"
    say "Switching to $name (this can take a while the first time)"
    # --option: a fresh install may not have flakes turned on yet
    sudo nixos-rebuild switch --flake ".#$name" --option experimental-features "nix-command flakes"
    ;;
  darwin)
    # nix-darwin refuses to replace these stock files; move them aside once
    for f in /etc/bashrc /etc/zshrc; do
      if [ -f "$f" ] && [ ! -L "$f" ]; then sudo mv "$f" "$f.before-nix-darwin"; fi
    done
    if grep -q 'nix.enable = true' "hosts/$name/default.nix" && [ -f /etc/nix/nix.conf ] && [ ! -L /etc/nix/nix.conf ]; then
      sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.before-nix-darwin
    fi
    say "Switching to $name (this can take a while the first time)"
    if command -v darwin-rebuild >/dev/null; then
      sudo darwin-rebuild switch --flake ".#$name"
    else
      sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake ".#$name"
    fi
    ;;
  home)
    say "Switching to $name (this can take a while the first time)"
    nix --extra-experimental-features "nix-command flakes" run home-manager -- switch -b backup --flake ".#$name"
    local fish="$HOME/.nix-profile/bin/fish"
    if [ -x "$fish" ] && [ "${SHELL:-}" != "$fish" ] && gum confirm "Make fish your login shell? (asks for sudo)"; then
      grep -qx "$fish" /etc/shells || echo "$fish" | sudo tee -a /etc/shells >/dev/null
      chsh -s "$fish"
    fi
    ;;
  esac

  header "✓ $name is set up"
  checklist
}

# ── Another machine (nixos-anywhere) ────────────────────────────────────────────
install_other_machine() {
  header "Install NixOS on another machine" \
    "" \
    "1. Boot it from the NixOS installer USB (minimal ISO is fine)." \
    "2. On it, run: passwd   (sets a temporary root password for SSH)" \
    "3. Note its IP address: ip addr" \
    "" \
    "Its whole disk will be erased."
  gum confirm "Ready?" || return 0

  local ip target name gui features disk encrypt system key_arg=()
  ip=$(gum input --header "IP address of the machine" --placeholder "192.168.1.50")
  [ -n "$ip" ] || die "No address"
  target="root@$ip"
  # nixos-anywhere makes many SSH connections; a key means one password prompt instead of dozens
  if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    mkdir -p "$HOME/.ssh"
    ssh-keygen -q -t ed25519 -N "" -f "$HOME/.ssh/id_ed25519"
  fi
  say "Connecting to $target (enter its root password if asked)"
  ssh-copy-id -o StrictHostKeyChecking=accept-new "$target" >/dev/null 2>&1 || true

  local arch disks
  arch=$(ssh "$target" uname -m)
  system="$arch-linux"
  disks=$(ssh "$target" lsblk -dno NAME,SIZE,MODEL -e 7,11 | sed 's/^/\/dev\//')
  [ -n "$disks" ] || die "No disks found on $ip"
  disk=$(echo "$disks" | gum choose --header "Disk to erase and install onto" | awk '{print $1}')

  name=$(ask_name "" allow-existing)
  if [ -e "hosts/$name" ]; then
    gum confirm "hosts/$name already exists (an earlier attempt?). Replace it?" || return 0
    rm -rf "hosts/$name"
  fi
  gui=$(ask_gui "Desktop (apps, window manager)")
  features=$(ask_features)
  encrypt=false
  if gum confirm "Encrypt the disk? (you'll type a passphrase at every boot, so skip for headless servers)"; then encrypt=true; fi

  local dir="hosts/$name" uefi
  uefi=$(ssh "$target" '[ -d /sys/firmware/efi ] && echo yes || echo no')
  write_host_nix "$dir" nixos "$system" "$gui" "$features"
  echo '{ }' >"$dir/hardware-configuration.nix" # filled in by nixos-anywhere
  cat >"$dir/disk.nix" <<EOF
# Disk layout (modules/disko): erases $disk
{
  imports = [ ../../modules/disko ];
  disk = {
    device = "$disk";
    encrypt = $encrypt;
  };
}
EOF
  local boot
  if [ "$uefi" = yes ]; then
    boot='boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;'
  else
    boot='boot.loader.grub.enable = true; # legacy BIOS; disko points it at the disk'
  fi
  cat >"$dir/default.nix" <<EOF
# Things specific to $name. Everything shared is in modules/nixos.
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disk.nix
  ];

  $boot

  # The NixOS release this machine was first installed with; don't change it.
  system.stateVersion = "$(nix eval --raw --inputs-from . nixpkgs#lib.trivial.release 2>/dev/null || echo 26.05)";
}
EOF
  git add "$dir"

  # Its SSH host key is made here, so the secrets can be encrypted for it before it exists
  TMP_EXTRA=$(mktemp -d) # copied onto the new machine as-is
  TMP_KEYS=$(mktemp -d)  # stays here
  install -d -m 755 "$TMP_EXTRA/etc/ssh"
  ssh-keygen -q -t ed25519 -N "" -C "root@$name" -f "$TMP_EXTRA/etc/ssh/ssh_host_ed25519_key"
  if [ -f .sops.yaml ]; then
    authorize_host_key "$TMP_EXTRA/etc/ssh/ssh_host_ed25519_key.pub" "$name"
  else
    warn "No secrets set up yet, so no login password will be set. Log in over Tailscale SSH or a key in keys/, then run passwd."
  fi

  if [ "$encrypt" = true ]; then
    local pass1 pass2
    pass1=$(gum input --password --header "Disk encryption passphrase")
    pass2=$(gum input --password --header "Again")
    [ "$pass1" = "$pass2" ] || die "Passphrases don't match"
    printf '%s' "$pass1" >"$TMP_KEYS/disk.key"
    key_arg=(--disk-encryption-keys /tmp/disk.key "$TMP_KEYS/disk.key")
  fi

  say "Installing $name on $ip"
  nixos-anywhere \
    --flake ".#$name" \
    --target-host "$target" \
    --generate-hardware-config nixos-generate-config "$dir/hardware-configuration.nix" \
    --extra-files "$TMP_EXTRA" \
    --chown /etc/ssh 0:0 \
    "${key_arg[@]}"
  git add "$dir"

  header "✓ $name is installed and rebooting"
  say "Once it's up: log in, run \`sudo tailscale up\`, then it's reachable as $name from all your machines."
  checklist
}

# ── Secrets (sops + YubiKey) ────────────────────────────────────────────────────
setup_secrets() {
  header "Secrets" "" \
    "Encrypted in secrets/*.yaml. Your YubiKey can decrypt them (to edit), and so can" \
    "each NixOS machine's SSH host key (to use them at boot). Plug in your YubiKey."
  gum confirm "Continue?" || return 0

  mkdir -p "$(dirname "$AGE_KEYS")"
  local recipient
  recipient=$(age-plugin-yubikey --list 2>/dev/null | grep -m1 '^age1yubikey' || true)
  if [ -z "$recipient" ]; then
    say "No age key on this YubiKey yet; creating one (set a PIN if it asks, then touch it)"
    age-plugin-yubikey --generate --name nix-config --pin-policy once --touch-policy cached
    recipient=$(age-plugin-yubikey --list | grep -m1 '^age1yubikey')
  fi
  # The identity file only says which YubiKey slot to use; the key never leaves the YubiKey
  age-plugin-yubikey --identity >>"$AGE_KEYS"
  sort -u "$AGE_KEYS" -o "$AGE_KEYS"

  if [ ! -f .sops.yaml ]; then
    cat >.sops.yaml <<'EOF'
# Who can decrypt secrets/*.yaml: your YubiKey(s), to edit them, and each machine's
# SSH host key, to use them at boot. Maintained by `nix run .#provision`.
# After changing this list by hand: sops updatekeys secrets/<file>.yaml
creation_rules:
  - path_regex: secrets/[^/]+\.yaml$
    key_groups:
      - age: []
EOF
  fi
  if ! age_recipient_known "$recipient"; then
    age_recipient_add "$recipient" "yubikey"
    for f in secrets/*.yaml; do [ -e "$f" ] && sops updatekeys -y "$f"; done
    say "Added this YubiKey. Run this again with a second YubiKey plugged in to have a backup."
  fi
  if [ -e /etc/NIXOS ] && [ -f /etc/ssh/ssh_host_ed25519_key.pub ]; then
    authorize_host_key /etc/ssh/ssh_host_ed25519_key.pub "$(hostname -s)"
  fi

  if [ ! -f secrets/common.yaml ] || gum confirm "Change the login password for new machines?"; then
    local p1 p2
    p1=$(gum input --password --header "Login password for $USERNAME on new NixOS machines")
    p2=$(gum input --password --header "Again")
    [ "$p1" = "$p2" ] || die "Passwords don't match"
    local hash tmp
    hash=$(openssl passwd -6 "$p1")
    tmp=$(mktemp)
    printf 'user-password: "%s"\n' "$hash" >"$tmp"
    sops encrypt --filename-override secrets/common.yaml "$tmp" >"$tmp.enc"
    mv "$tmp.enc" secrets/common.yaml
    rm -f "$tmp"
  fi

  if gum confirm --default=no "Store a Tailscale auth key so new machines join your tailnet by themselves?"; then
    say "Make one at https://login.tailscale.com/admin/settings/keys (reusable)"
    local key tmp
    key=$(gum input --password --header "Tailscale auth key (tskey-auth-...)")
    tmp=$(mktemp)
    printf 'tailscale-authkey: "%s"\n' "$key" >"$tmp"
    sops encrypt --filename-override secrets/tailscale.yaml "$tmp" >"$tmp.enc"
    mv "$tmp.enc" secrets/tailscale.yaml
    rm -f "$tmp"
  fi

  git add .sops.yaml secrets
  header "✓ Secrets ready" "Edit them any time with: sops secrets/common.yaml"
}

# ── Menu ─────────────────────────────────────────────────────────────────────────
header "nix-config: $REPO"
case $(gum choose "Set up this machine" "Install NixOS on another machine (erases it)" "Set up secrets (YubiKey)" "Quit") in
"Set up this machine") setup_this_machine ;;
"Install NixOS on another machine (erases it)") install_other_machine ;;
"Set up secrets (YubiKey)") setup_secrets ;;
*) exit 0 ;;
esac
