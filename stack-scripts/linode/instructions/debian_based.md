# Debian Based Server Stack Script

A stack script designed to quickly deploy a new debian based server.

## Compatible With:
- Ubuntu 18.04 LTS
- Debian 9

## SSH Keys
To setup ssh private/public keys with this script, you need to do the following:
- On your local machine, run "ssh-keygen" in the terminal
    - For increased security of of your key, increase the size with with the `-b` flag, like this: `sssh-keygen -b 4096`
- Follow the prompts and be sure to enter a passphrase for the key
- If you accepted the defaults, it will generate a private key in a `~/.ssh/id_rsa` file, and a public key in a `~/.ssh/id_rsa.pub` file
- Open and copy the contents of the public key (should be something like `ssh rsa ...`) into the field for the SSH pubkey for this script
- You will also need to import the private key into your ssh client 