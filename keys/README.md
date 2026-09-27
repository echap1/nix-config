SSH public keys (`*.pub`) in this folder are allowed to log in as `ethan` on every
NixOS machine. Only public keys go here. A YubiKey-backed key works well:

    ssh-keygen -t ed25519-sk -O resident -O verify-required -C "yubikey"
    cp ~/.ssh/id_ed25519_sk.pub keys/yubikey.pub
