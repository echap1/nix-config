# Tailscale: every machine reachable from anywhere by name (ssh <host>, sftp://<host>).
# First time on each machine: `tailscale up` and sign in (or set up an auth key in sops).
{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  authKeyFile = ../../secrets/tailscale.yaml;
  hasAuthKey = builtins.pathExists authKeyFile;
in
{
  services.tailscale = {
    enable = true;
    openFirewall = true;
    # --ssh: Tailscale SSH, so `ssh <host>` and sftp work between your machines without keys.
    # --operator: lets you run `tailscale` (and share folders) without sudo.
    extraSetFlags = [
      "--ssh"
      "--operator=${username}"
    ];
    # Joins the tailnet on its own when secrets/tailscale.yaml holds an auth key
    # (the provision script offers to add one). Otherwise run `tailscale up` once.
    authKeyFile = lib.mkIf hasAuthKey config.sops.secrets.tailscale-authkey.path;
    extraUpFlags = [ "--ssh" ];
  };

  sops.secrets.tailscale-authkey = lib.mkIf hasAuthKey { sopsFile = authKeyFile; };

  # Everything arriving over Tailscale is from your own devices
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # Taildrive: shares your home folder with your other devices. Open it from
  # Finder (Cmd-K) or Nautilus at http://100.100.100.100:8080 (dav:// in Nautilus).
  # Needs Taildrive allowed in the tailnet policy once (see README).
  systemd.user.services.taildrive-home = {
    description = "Share home folder over Taildrive";
    wantedBy = [ "default.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      for _ in $(seq 1 60); do
        if ${lib.getExe pkgs.tailscale} status >/dev/null 2>&1; then
          ${lib.getExe pkgs.tailscale} drive share home "$HOME" \
            || echo "Taildrive sharing not allowed yet (see README)"
          exit 0
        fi
        sleep 5
      done
      echo "Tailscale isn't connected; skipping Taildrive share"
    '';
  };
}
