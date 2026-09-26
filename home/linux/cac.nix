# CAC in Brave on Linux. Chromium browsers use the NSS database in ~/.pki/nssdb rather than
# the system trust store, so each switch registers the card driver and the DoD certs there.
{ pkgs, lib, ... }:
let
  dod = pkgs.callPackage ../../certs/dod { };
  certutil = "${pkgs.nssTools}/bin/certutil";
  modutil = "${pkgs.nssTools}/bin/modutil";
in
{
  home.activation.cacNssdb = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    nssdir="$HOME/.pki/nssdb"
    db="sql:$nssdir"
    run mkdir -p "$nssdir"
    if [ ! -f "$nssdir/cert9.db" ]; then
      run ${certutil} -N -d "$db" --empty-password
    fi

    # Card driver. Re-added every switch so it always points at the current OpenSC.
    run ${modutil} -dbdir "$db" -delete "OpenSC" -force >/dev/null 2>&1 || true
    run ${modutil} -dbdir "$db" -add "OpenSC" -libfile ${pkgs.opensc}/lib/opensc-pkcs11.so -force >/dev/null

    # DoD roots trusted for websites and email; intermediates stored for building chains
    for f in ${dod}/roots/*.pem; do
      run ${certutil} -A -d "$db" -n "$(basename "$f" .pem)" -t "CT,C,C" -i "$f"
    done
    for f in ${dod}/intermediates/*.pem; do
      run ${certutil} -A -d "$db" -n "$(basename "$f" .pem)" -t ",," -i "$f"
    done
  '';
}
