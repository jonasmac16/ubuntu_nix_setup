#!/usr/bin/env bash
set -euo pipefail

echo "=========================================================="
echo " Bootstrapping System Environment via Unified Infrastructure Tree"
echo "=========================================================="

# 1. Collect secure access credentials
read -rs -p "[?] Input secure repository personal access token (PAT): " TX_TOKEN
echo ""

# 2. Update minimal baseline package states
echo "[-] Provisioning target dependencies..."
sudo apt update
sudo apt install -y ansible git curl

# 3. Mount fallback staging authorization assets
echo "https://oauth2:${TX_TOKEN}@github.com" > ~/.git-credentials
echo "https://oauth2:${TX_TOKEN}@gitlab.com" >> ~/.git-credentials
chmod 600 ~/.git-credentials

# 4. Trigger localized loopback playbook executions
HOSTNAME_LIMIT="$(hostname)"
if ! grep -qE "^${HOSTNAME_LIMIT}([[:space:]]|$)" ansible/inventory.ini; then
    echo "ERROR: this machine's hostname '${HOSTNAME_LIMIT}' is not in ansible/inventory.ini."
    echo "Add an entry matching 'hostname' so the playbook can self-select this machine."
    exit 1
fi
echo "[-] Executing Ansible hardware execution layers for host '${HOSTNAME_LIMIT}'..."
VAULT_ARGS="--ask-vault-pass"
if [ -f "$HOME/.ansible/vault_pass" ]; then
    VAULT_ARGS="--vault-password-file $HOME/.ansible/vault_pass"
fi
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --connection=local -l "$HOSTNAME_LIMIT" --ask-become-pass $VAULT_ARGS

# 5. Bootstrap standalone Nix layers
if [ ! -d "/nix" ]; then
    echo "[-] Installing Nix framework..."
    curl -L https://nixos.org | sh -s -- --daemon
    . /etc/profile.d/nix.sh
else
    echo "[*] Nix cluster paths are already configured"
fi

# 6. Map target tracking channel trees
echo "[-] Updating Home Manager indices..."
nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update

# 7. Connect configuration paths into operational runtime directories
echo "[-] Linking local configurations..."
mkdir -p ~/.config/home-manager
ln -sf "$(pwd)/nix/home.nix" ~/.config/home-manager/home.nix

# 8. Compile user profile
echo "[-] Initiating user profile generation..."
nix-shell '<home-manager>' -A install

echo "=========================================================="
echo " Alignment Complete. Reboot your machine to enter Sway!"
echo "=========================================================="
