# DoD PKI certificates (bundle v5.14, from dl.dod.cyber.mil unclass-certificates_pkcs7_DoD.zip).
# Splits roots.pem / intermediates.pem into one file per certificate, named by common name.
# To update: download the new bundle, then regenerate the two .pem files.
{ runCommand, openssl }:
runCommand "dod-certs" { nativeBuildInputs = [ openssl ]; } ''
  split() {
    mkdir -p "$2"
    awk -v dir="$2" '/BEGIN CERTIFICATE/{n++; f=sprintf("%s/%03d.pem", dir, n)} f{print > f} /END CERTIFICATE/{close(f); f=""}' "$1"
    for f in "$2"/*.pem; do
      cn=$(openssl x509 -noout -subject -nameopt multiline -in "$f" | sed -n 's/^ *commonName *= *//p')
      mv "$f" "$2/$cn.pem"
    done
  }
  split ${./roots.pem} $out/roots
  split ${./intermediates.pem} $out/intermediates
''
