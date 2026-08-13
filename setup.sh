#!/usr/bin/env bash
set -euo pipefail

echo "=========================================================="
echo " Bootstrapping System Environment via Unified Infrastructure Tree"
echo "=========================================================="

# 1. Update minimal baseline package states
echo "[-] Provisioning target dependencies..."
sudo apt update
sudo apt install -y ansible git curl

echo "[-] Installing required Ansible collections..."
ansible-galaxy collection install -r ansible/collections/requirements.yml

# 2. Trigger localized loopback playbook executions
HOSTNAME_LIMIT="$(hostname)"
if ! grep -qE "^${HOSTNAME_LIMIT}([[:space:]]|$)" ansible/inventory.ini; then
    echo "ERROR: this machine's hostname '${HOSTNAME_LIMIT}' is not in ansible/inventory.ini."
    echo "Add an entry matching 'hostname' so the playbook can self-select this machine."
    exit 1
fi
if [ ! -f "nix/hosts/${HOSTNAME_LIMIT}.nix" ]; then
    echo "ERROR: no Nix host module exists at nix/hosts/${HOSTNAME_LIMIT}.nix."
    echo "Create the host module before bootstrapping this machine."
    exit 1
fi
echo "[-] Executing Ansible hardware execution layers for host '${HOSTNAME_LIMIT}'..."
VAULT_ARGS="--ask-vault-pass"
if [ -f "$HOME/.ansible/vault_pass" ]; then
    VAULT_ARGS="--vault-password-file $HOME/.ansible/vault_pass"
fi
# Optional per-run overrides, e.g. ANSIBLE_EXTRA_ARGS="-e install_nvidia=false"
ANSIBLE_EXTRA_ARGS="${ANSIBLE_EXTRA_ARGS:-}"
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --connection=local -l "$HOSTNAME_LIMIT" --ask-become-pass $VAULT_ARGS $ANSIBLE_EXTRA_ARGS

# 3. Bootstrap standalone Nix layers
if [ ! -d "/nix" ]; then
    echo "[-] Installing Nix framework..."
    curl -L https://releases.nixos.org/nix/nix-2.34.8/install | sh -s -- --daemon
    . /etc/profile.d/nix.sh
else
    echo "[*] Nix cluster paths are already configured"
fi

# 4. Enable flake support (needed for host-specific Nix builds and
#    `home-manager switch --flake`). The daemon must pick up the change.
echo "[-] Enabling Nix flake support..."
sudo mkdir -p /etc/nix
if ! grep -q "^experimental-features = nix-command flakes" /etc/nix/nix.conf 2>/dev/null; then
    echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf >/dev/null
fi
if command -v systemctl >/dev/null 2>&1 && systemctl is-system-running >/dev/null 2>&1; then
    sudo systemctl restart nix-daemon || true
fi

# 5. Lock the flake inputs (nixpkgs, home-manager, NUR) for reproducibility
echo "[-] Locking flake inputs..."
nix flake lock

# 6. Build and activate the user profile from this repository's flake.
#    The host is selected explicitly, so evaluation does not depend on
#    /etc/hostname.
echo "[-] Building user profile..."
nix build ".#home-${HOSTNAME_LIMIT}"
HOME_MANAGER_BACKUP_EXT=backup ./result/activate

echo "=========================================================="
echo " Alignment Complete. Reboot your machine to enter Sway!"
echo "=========================================================="
