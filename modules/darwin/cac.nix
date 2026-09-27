# CAC on macOS. Card readers work natively (CryptoTokenKit), so only the DoD roots are needed:
# they're added to the System keychain, which Safari, Brave and other Mac apps use.
# macOS may ask for your password the first time each root is added.
{ pkgs, ... }:
let
  dod = pkgs.callPackage ../../certs/dod { };
  keychain = "/Library/Keychains/System.keychain";
in
{
  system.activationScripts.postActivation.text = ''
    for f in ${dod}/roots/*.pem; do
      name="$(basename "$f" .pem)"
      if ! /usr/bin/security find-certificate -c "$name" ${keychain} >/dev/null 2>&1; then
        echo "adding $name to the System keychain"
        /usr/bin/security add-trusted-cert -d -r trustRoot -k ${keychain} "$f" \
          || echo "warning: could not add $name (add it in Keychain Access instead)" >&2
      fi
    done
    for f in ${dod}/intermediates/*.pem; do
      name="$(basename "$f" .pem)"
      if ! /usr/bin/security find-certificate -c "$name" ${keychain} >/dev/null 2>&1; then
        /usr/bin/security add-certificates -k ${keychain} "$f" >/dev/null 2>&1 || true
      fi
    done
  '';
}
