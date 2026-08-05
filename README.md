# nix-ubuntu-infra

A declarative, drift-free desktop environment for multiple Ubuntu machines from a single Git repository.

This repository gives you a **NixOS-like workflow on Ubuntu**. Every machine is rebuilt from a known state: system hardware and permissions are managed by Ansible running locally, while user packages, dotfiles and window-manager configuration are managed by the standalone Nix package manager and Home Manager.

The result: a workstation and a laptop that are guaranteed to converge to the same configured state, with no manual `apt install` drift, no forgotten dotfiles, and no "works only on this box" setup scripts.

---

## Table of Contents

- [How It Works](#how-it-works)
- [The Golden Boundary](#the-golden-boundary)
- [Repository Layout](#repository-layout)
- [Prerequisites](#prerequisites)
- [First-Time Setup on a Fresh Machine](#first-time-setup-on-a-fresh-machine)
  - [Step 1 — Prepare the base install](#step-1--prepare-the-base-install)
  - [Step 2 — Initialize the Git repository](#step-2--initialize-the-git-repository)
  - [Step 3 — Register your machine in the inventory](#step-3--register-your-machine-in-the-inventory)
  - [Step 4 — Create your host-specific configuration](#step-4--create-your-host-specific-configuration)
  - [Step 5 — Create and encrypt the secrets vault](#step-5--create-and-encrypt-the-secrets-vault)
  - [Step 6 — Set your real username in Home Manager](#step-6--set-your-real-username-in-home-manager)
  - [Step 7 — Commit and push the initial state](#step-7--commit-and-push-the-initial-state)
  - [Step 8 — Run the bootstrap script](#step-8--run-the-bootstrap-script)
  - [Step 9 — First login into Sway](#step-9--first-login-into-sway)
- [What the Bootstrap Actually Does](#what-the-bootstrap-actually-does)
- [Daily Operations](#daily-operations)
- [Adding a Second Machine](#adding-a-second-machine)
- [Common Configuration vs Host-Specific Configuration](#common-configuration-vs-host-specific-configuration)
- [Security Reference](#security-reference)
- [Troubleshooting & FAQ](#troubleshooting--faq)
- [Extension Ideas](#extension-ideas)

---

## How It Works

```
+-----------------------------------------------------------------+
|             User Layer: Nix & Home Manager                       |
|  - CLI & Dev Tools (Neovim, Git)     - Dotfile Templating       |
|  - User Env (Bash, Path Engine)      - User Symlinks (~/NAS)    |
|  - Wayland WM (Sway), Bar, Launcher  - SSH/Git rules            |
+-----------------------------------------------------------------+
                                |
+-----------------------------------------------------------------+
|          Infrastructure Layer: Ansible Local                     |
|  - Hardware Drivers (NVIDIA)         - Networking (Wi-Fi, VPN)   |
|  - System Daemons (Greetd, Seatd)    - Systemd Automounts       |
|  - Credentials / Secrets Deployment  - APT System Packages      |
+-----------------------------------------------------------------+
                                |
+-----------------------------------------------------------------+
|                      Base Linux OS Layer                         |
|  - Baseline Ubuntu Minimal Server / Core Installation           |
+-----------------------------------------------------------------+
```

Two independent tools converge the machine:

| Tool | Scope | Runs as | Manages |
|------|-------|---------|---------|
| **Ansible** | System / root | `sudo` | APT packages, NVIDIA drivers, network profiles, `greetd`/`seatd`, systemd NFS/SMB automounts, secrets deployment |
| **Nix + Home Manager** | User space | your account | CLI tools, user packages, `.config/*` dotfiles, Sway, Bash/SSH/Git config, NAS symlinks |

Everything is executed **locally on the target machine** (`ansible_connection=local`) — no control node, no SSH to yourself, no server component. The repository is cloned from Git and applied on each host.

The machine's configuration flags are selected per host (see [Common Configuration vs Host-Specific Configuration](#common-configuration-vs-host-specific-configuration)).

## The Golden Boundary

The single most important rule in this repository:

> **Never hand-edit a machine. Always edit the repository, commit, and re-apply.**

| Layer | Owns | You must NOT do |
|-------|------|-----------------|
| **Ansible (root)** | Operations needing `sudo`; global files in `/etc/`; kernel/variable changes; hardware power engines; deployment of encrypted secret assets (SSH private keys, Git tokens) | `sudo apt install <package>` by hand |
| **Nix + Home Manager (user)** | Everything inside your terminal/home bubble: software versions, user dotfiles (`.config/*`), window manager aesthetics, shortcuts | Editing `~/.config/*` or `~/.bashrc` directly |

If you need something on the system, you add it to `ansible/playbook.yml`. If you need a user tool or config, you add it to `nix/modules/*.nix`. Then you push and re-apply — on this machine or any other.

## Repository Layout

```
nix-ubuntu-infra/
├── .gitignore                 # Blocks retry files, plaintext secrets, Nix build outputs
├── README.md                  # This document
├── setup.sh                   # One-shot bootstrap for a fresh Ubuntu machine
│
├── ansible/                   # System hardware & package alignment
│   ├── inventory.ini          # Local-loopback inventory, grouped by machine role
│   ├── playbook.yml           # Main infrastructure playbook (sections A + B)
│   └── host_vars/
│       ├── all/               # COMMON configuration — applies to every machine
│       │   ├── vars.yml       # Non-sensitive values + machine-agnostic defaults
│       │   └── secrets.yml    # ANSIBLE-VAULT ENCRYPTED secrets (gitignored)
│       ├── my-workstation.yml # Host-specific overrides (example: desktop)
│       └── my-laptop.yml      # Host-specific overrides (example: laptop)
│
└── nix/                       # User profile convergence layer
    ├── home.nix               # Central Home Manager gateway
    └── modules/
        ├── sway.nix           # Wayland compositor, bar, launcher
        └── shell.nix          # Bash aliases, SSH blocks, Git rules
```

## Prerequisites

- **OS**: Ubuntu 26.04 LTS (Resolute Raccoon). A **minimal / server** install is recommended — the playbook installs every desktop component itself, so a full desktop image would only duplicate things. Network access is required during install.
- **User account**: You need a user in the `sudo` group (created during Ubuntu install).
- **Credentials**: A Git personal access token (PAT) for the private repository containing this tree, plus real values for the secrets in the vault (WiFi password, NAS/SMB credentials, Git token/email, an SSH private key).
- **Hardware expectations**: The sample config assumes a NAS at `192.168.1.100` exporting an NFS share (`/volume1/nfs_data`) and an SMB share (`smb_data`). Adjust `host_vars/all/vars.yml` if your storage lives elsewhere.

Everything else (`git`, `curl`, `ansible`) is installed by `setup.sh` on the fresh machine.

---

## First-Time Setup on a Fresh Machine

### Step 1 — Prepare the base install

1. Install Ubuntu (minimal/server) normally.
2. Create your primary user and make sure it is in the `sudo` group.
3. Connect to the network (Ethernet, or Wi-Fi via `nmcli` / `nmtui`).
4. Open a terminal and verify the machine's hostname — you will use it shortly:

   ```bash
   hostname
   ```

   Example output: `thinkpad-x1` or `ryzen-desktop`.

### Step 2 — Initialize the Git repository

The assumption is that this tree lives in a **private Git repository** (it contains infrastructure secrets once the vault is populated).

On the machine that hosts the canonical repository:

```bash
git init
git add -A
git commit -m "Initial infrastructure tree"
git branch -M main
git remote add origin https://github.com/<you>/nix-ubuntu-infra.git
git push -u origin main
```

> **Note on the secrets file**: `ansible/host_vars/all/secrets.yml` is listed in `.gitignore`. Until you encrypt it (Step 5), the template will still be tracked if you added it with `git add -A` above. If you committed the plaintext template, that is fine — just encrypt it before adding real values, per Step 5.

If you already have this repository hosted, skip straight to cloning it on the target machine.

### Step 3 — Register your machine in the inventory

Open `ansible/inventory.ini`. It ships with two **example** hosts:

```ini
[workstations]
my-workstation ansible_host=localhost ansible_connection=local

[laptops]
my-laptop ansible_host=localhost ansible_connection=local

[ubuntu:children]
workstations
laptops
```

The `[ubuntu:children]` group is what `setup.sh` targets (`-l ubuntu`), so **every host listed here gets configured on every run**. For a real single machine, replace the examples with your own entry:

```ini
[workstations]
ryzen-desktop ansible_host=localhost ansible_connection=local

[laptops]
thinkpad-x1 ansible_host=localhost ansible_connection=local

[ubuntu:children]
workstations
laptops
```

Remove (or comment out) the example hosts you don't use. If you run this config on only one machine, keep only that one entry — otherwise both host configurations would be applied on the same machine.

### Step 4 — Create your host-specific configuration

Copy the appropriate example to your machine's hostname:

```bash
# For a desktop
cp ansible/host_vars/my-workstation.yml ansible/host_vars/ryzen-desktop.yml

# For a laptop
cp ansible/host_vars/my-laptop.yml ansible/host_vars/thinkpad-x1.yml
```

Each file only needs to contain the **overrides** relative to the common configuration:

```yaml
---
is_laptop: true
install_nvidia: false
additional_packages:
  - tlp
  - powertop
```

The fields:

| Variable | Purpose | Default (common) |
|----------|---------|------------------|
| `is_laptop` | Enables TLP battery preservation daemon | `false` |
| `install_nvidia` | Installs `nvidia-driver-595` | `false` |
| `additional_packages` | Extra APT packages for this machine | `[]` |

You can delete the example files (`my-workstation.yml`, `my-laptop.yml`) once your real per-host files exist, or keep them as templates.

### Step 5 — Create and encrypt the secrets vault

The file `ansible/host_vars/all/secrets.yml` holds plaintext secret values and is **gitignored**. Create a real one and encrypt it before putting any real data in.

1. Copy the template and open it for the first time:

   ```bash
   ansible-vault create ansible/host_vars/all/secrets.yml
   ```

   This launches your `$EDITOR` (set `EDITOR=nano` or `EDITOR=vim` first if needed). Paste the template structure:

   ```yaml
   ---
   vault_home_wifi_password: "MyActualWiFiPassword"
   vault_smb_username: "samba_nas_user"
   vault_smb_password: "SambaNASPassword"
   vault_git_token: "github_pat_..._alphanumeric"
   vault_git_email: "you@example.com"
   vault_ssh_private_key: |
     -----BEGIN OPENSSH PRIVATE KEY-----
     <your actual ed25519 or RSA private key data>
     -----END OPENSSH PRIVATE KEY-----
   ```

   On first save, `ansible-vault` prompts for a vault password. **Remember it** — you will need it for every `--ask-vault-pass` run.

2. Verify the file is encrypted (the content is now `$ANSIBLE_VAULT;...`):

   ```bash
   head -1 ansible/host_vars/all/secrets.yml
   ```

3. To view or edit the vault later:

   ```bash
   ansible-vault view  ansible/host_vars/all/secrets.yml
   ansible-vault edit  ansible/host_vars/all/secrets.yml
   ```

> The encrypted file is still gitignored, so it lives only on the machines where you create it. To propagate it to a second machine, decrypt it, scp it over, and re-encrypt there — or better, keep a copy in your password manager. **Never commit the plaintext or a decrypted copy.**

### Step 6 — Set your real username in Home Manager

Open `nix/home.nix` and replace the placeholders:

```nix
home.username = "your_username";          # -> your login name
home.homeDirectory = "/home/your_username"; # -> matching absolute path
home.stateVersion = "26.05";               # leave alone unless you know why you're changing it
```

Also set the Git identity and SSH `matchBlocks` host in `nix/modules/shell.nix` (username, email, and the NAS endpoint user/host) — these are wired into the Git and SSH config Home Manager generates.

### Step 7 — Commit and push the initial state

```bash
git add -A
git commit -m "Configure host: ryzen-desktop"
git push origin main
```

### Step 8 — Run the bootstrap script

Clone and run the setup on the fresh machine:

```bash
git clone https://github.com/<you>/nix-ubuntu-infra.git ~/src/nix-ubuntu-infra
cd ~/src/nix-ubuntu-infra
./setup.sh
```

`setup.sh` will prompt you for:

- **PAT** — your Git personal access token (used to create `~/.git-credentials` for future pulls).
- **Become password** — your `sudo` password (Ansible escalates to root).
- **Vault password** — the password you set in Step 5.

The script runs each phase with an on-screen `[-]` label. See [What the Bootstrap Actually Does](#what-the-bootstrap-actually-does) for the phase-by-phase breakdown, including what it looks like when everything succeeds.

> If you prefer to run the phases manually (for example, to watch each one), execute them in order: install `ansible`, run `ansible-playbook -i ansible/inventory.ini ansible/playbook.yml -l ubuntu --ask-become-pass --ask-vault-pass`, then install Nix, then build Home Manager. `setup.sh` is just a wrapper around those exact steps.

### Step 9 — First login into Sway

Reboot:

```bash
sudo reboot
```

`greetd` starts a graphical login. Log in with your user — the session launches **Sway** (Wayland) with:

- **Foot** terminal (`Super + Enter`)
- **Wofi** application launcher (`Super + D`)
- **Waybar** status bar at the top (started automatically)
- **Mako** desktop notifications

Your NAS shares are mounted at `~/NAS-NFS` and `~/NAS-SMB` (symlinks into `/mnt/nas/...`, automounted on access by systemd).

---

## What the Bootstrap Actually Does

`setup.sh` has eight phases.

### Phase 1-2 — Credentials and base dependencies

- Reads your PAT (hidden input).
- `sudo apt update && sudo apt install -y ansible git curl`.
- Writes `~/.git-credentials` (mode `0600`) with `https://oauth2:<TOKEN>@github.com` and `@gitlab.com`, so future `git pull`/`git push` from this repo authenticate without interactive prompts.

### Phase 3 — Ansible playbook (the long one)

The playbook (`ansible/playbook.yml`) runs in two blocks.

**Section A — privileged core provisioning (`become: true`):**

| Task | Effect |
|------|--------|
| Install core display components | `sway`, `swaylock`, `swayidle`, `xwayland`, `seatd`, `dbus-x11`, `network-manager` |
| Install NVIDIA drivers | `nvidia-driver-595` — only when `install_nvidia: true` |
| Configure PipeWire | `pipewire`, `pipewire-pulse`, `wireplumber` for Wayland-native audio |
| Bind user to hardware groups | Adds your user to `video`, `input` groups (needed for Wayland input/DRM) |
| Enable `seatd` | Starts the seat management daemon (login-session-free input/DRM access) |
| Configure Home WiFi | Creates a `Home-WiFi` network profile via `nmcli` using the vault password |
| Install display manager | `greetd` + `cage`, then deploys `/etc/greetd/config.toml` that boots straight into `sway` and restarts the service |
| Install storage clients | `nfs-common`, `cifs-utils`; creates `/mnt/nas/nfs` and `/mnt/nas/smb` |
| Deploy SMB credentials | `/etc/samba/.smbcredentials` (mode `0600`, root-owned) from vault values |
| Deploy automount units | Writes `mnt-nas-nfs.mount`/`.automount` and `mnt-nas-smb.mount`/`.automount` to `/etc/systemd/system/`, runs `daemon_reload`, enables + starts both automounts (mount-on-access, idle-unmount after 300 s) |
| Enable TLP | Only when `is_laptop: true` |

**Section B — user space (`become: false`):**

| Task | Effect |
|------|--------|
| SSH directory | Ensures `~/.ssh` exists (mode `0700`) |
| SSH private key | Writes `~/.ssh/id_ed25519` (mode `0600`) from the vault |
| Bin directory | Ensures `~/.local/bin` exists |
| Git credentials | Writes `~/.git-credentials` (mode `0600`) from the vault token |
| Download Discord | Fetches the Discord `.deb` to `/tmp` and installs it via APT |
| Install Rustup | Runs the official `rustup` installer (skipped if `~/.cargo/bin/rustc` already exists) |

### Phase 4 — Install Nix

If `/nix` does not exist, installs the **standalone Nix package manager** in daemon mode via the official installer, then sources `/etc/profile.d/nix.sh` for the rest of the script. On subsequent runs this is skipped.

### Phase 5 — Home Manager channels

Adds the `nixpkgs-unstable` and `home-manager` (master branch) channels, then runs `nix-channel --update`. This setup tracks the unstable channels rather than release channels, so `home.stateVersion` stays pinned to the current stable release for compatibility.

### Phase 6 — Link the configuration

Creates `~/.config/home-manager` and symlinks `nix/home.nix` into it, so `home-manager` reads exactly this repository's file.

### Phase 7 — Build the user profile

Runs `nix-shell '<home-manager>' -A install`, which downloads and builds the full user profile (all `home.packages`, Sway config, dotfiles, SSH/Git config, NAS symlinks). This is the slowest phase on a fresh machine.

---

## Daily Operations

All configuration is driven from this repository. The workflow is: **edit → commit → push → re-apply on whichever machines need it**.

### Where to change what

| I want to... | Edit |
|--------------|------|
| Install a system package (APT) | `ansible/playbook.yml` — Section A |
| Install system-wide drivers / daemons | `ansible/playbook.yml` — Section A |
| Change NAS mounts / mount options | `ansible/playbook.yml` (mount units) + `ansible/host_vars/all/vars.yml` (paths) |
| Change hardware flags for one machine | `ansible/host_vars/<hostname>.yml` |
| Add a user CLI tool / editor | `nix/home.nix` (`home.packages`) |
| Change Sway keybinds / workspaces | `nix/modules/sway.nix` |
| Change shell aliases / Git / SSH | `nix/modules/shell.nix` |

### The alias suite

`nix/modules/shell.nix` installs these Bash aliases (they become available after the Home Manager switch):

| Alias | Runs |
|-------|------|
| `infra-apply-system` | `ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --ask-become-pass --ask-vault-pass` — re-applies the system layer |
| `infra-apply-user` | `home-manager switch` — re-applies the user layer instantly |
| `infra-sync-all` | `git pull origin main && infra-apply-system && infra-apply-user` — pull + full converge |
| `infra-commit` | `git add -A && git commit -m` (append a message) |
| `infra-push` | `git push origin main` |
| `infra-save` | `git add -A && git commit -m 'wip automated configuration tracking save' && git push origin main` — quick snapshot |

### Typical session

```bash
cd ~/src/nix-ubuntu-infra

# User tools are pure Nix, no sudo:
vim nix/home.nix        # add "fd" to home.packages
infra-apply-user        # immediately available

# System-level changes need sudo:
vim ansible/playbook.yml
infra-apply-system      # prompts for sudo + vault password

# Save the state of the world:
infra-save
```

---

## Adding a Second Machine

1. On the new machine: `git clone https://github.com/<you>/nix-ubuntu-infra.git`.
2. Repeat [Step 3](#step-3--register-your-machine-in-the-inventory) — add this machine's hostname to the appropriate group in `inventory.ini`. Make sure the first machine is **not** also listed, or it will be reconfigured too.
3. Repeat [Step 4](#step-4--create-your-host-specific-configuration) — create `host_vars/<hostname>.yml` for the new machine.
4. Repeat [Step 5](#step-5--create-and-encrypt-the-secrets-vault) — create the vault **on the new machine** (it is gitignored).
5. Commit and push the inventory/host-var changes from any machine.
6. On the new machine: `./setup.sh`, then reboot.

From then on, `infra-sync-all` on either machine pulls the latest tree and converges it locally.

---

## Common Configuration vs Host-Specific Configuration

Configuration resolves in two layers:

```
host_vars/all/*              <- COMMON  (applies to every machine)
  └─ host_vars/<hostname>.yml <- SPECIFIC (overrides per machine)
```

Ansible merges `host_vars/all/vars.yml` into every host, then overlays `host_vars/<hostname>.yml` for the matching host (specific values win).

- Put things that are true everywhere in `host_vars/all/vars.yml` (NAS addresses, share paths, and the machine-agnostic defaults `is_laptop`/`install_nvidia`/`additional_packages`).
- Put things that differ per machine in `host_vars/<hostname>.yml` (laptop vs desktop flags, extra packages).

The secrets vault (`host_vars/all/secrets.yml`) is common by design — WiFi, NAS and Git credentials are assumed identical across your fleet. If you need per-machine secrets, create `host_vars/<hostname>.yml` mirroring the same variables with a different encryption.

---

## Security Reference

- **`ansible/host_vars/all/secrets.yml`** is the only secrets store. It must stay encrypted with `ansible-vault` and is gitignored. Plaintext runs of the playbook require `--ask-vault-pass`.
- **Vault cheat sheet:**

  ```bash
  ansible-vault create  <file>        # new encrypted file
  ansible-vault edit    <file>        # decrypt in $EDITOR, re-encrypt on save
  ansible-vault view    <file>        # decrypt to stdout
  ansible-vault rekey   <file>        # change the vault password
  ```

- The playbook deploys secrets with restrictive modes: `~/.ssh` (0700), `~/.ssh/id_ed25519` (0600), `~/.git-credentials` (0600), `/etc/samba/.smbcredentials` (0600, root-owned).
- The Git token used by `setup.sh` writes `~/.git-credentials` with mode `0600`. It is also the token used for cloning — if you rotate it, run the playbook again or rewrite the file.
- **Do not** commit decrypted vault files, plaintext `.env`-style secrets, or your real SSH private key anywhere else. The SSH key in the vault is deployed to `~/.ssh/id_ed25519` on each machine automatically.
- Back up your vault password in a password manager. Losing it means you cannot decrypt the secrets file.

---

## Troubleshooting & FAQ

**`ERROR! provided hosts list is empty`**
Your `inventory.ini` has no host in the `[ubuntu]` group, or all entries are commented out. Add your hostname entry (see Step 3).

**`Vault password was not provided`**
Run with `--ask-vault-pass` (the aliases already do). If you just created the vault, make sure the file is actually encrypted (`head -1 ...secrets.yml` should start with `$ANSIBLE_VAULT`).

**NVIDIA driver fails to install / won't load**
`nvidia-driver-595` is the packaged NVIDIA driver for Ubuntu 26.04 (kernel 7.0). If your GPU is Turing-generation or newer and you want the open kernel module variant, switch to `nvidia-driver-595-open` in `ansible/playbook.yml` (Section A, "Provision native proprietary graphics drivers"). Alternatively, run `ubuntu-drivers install` once to let Ubuntu pick the driver it recommends for your card. Then re-run `infra-apply-system`.

**`nmcli` task fails: NetworkManager not running**
`network-manager` is installed by the playbook, but if the base system uses `netplan`/`systemd-networkd`, NetworkManager may not be active. Verify with `systemctl status NetworkManager` and `systemctl enable --now NetworkManager`, or adjust the WiFi task to your network backend.

**greetd shows a black screen / Sway doesn't start**
Check `systemctl status greetd` and the log at `/var/log/greetd/`. The default config runs `cage agreety --cmd sway`. If Sway itself fails, run `sway -d` from a TTY to see diagnostics; missing `seatd` or `video`/`input` group membership is the usual cause.

**`nix-channel`/`home-manager` not found**
You must log into a fresh shell (or source `/etc/profile.d/nix.sh`) after installing Nix. If the setup script ran without a reboot, run `. /etc/profile.d/nix.sh` first.

**`nix-shell '<home-manager>' -A install` fails on new Nix**
Older installs used the `nixos` channel; standalone installs need `nixpkgs` as well. Ensure `nix-channel --list` shows `nixpkgs` (pointing at `nixpkgs-unstable`) and `home-manager` (pointing at the master branch tarball), then `nix-channel --update`. If the error mentions an unstable module API, your Nix/Home Manager are version-mismatched — upgrade Home Manager (`home-manager upgrade`) before retrying.

**Discord `.deb` download or install fails**
Transient download failures or new architecture packages. Re-run `infra-apply-system`. To skip Discord entirely, comment out the two Discord tasks in `ansible/playbook.yml` (Section B).

**`rustup` task fails: curl error**
The installer is fetched from the internet; re-run the playbook (the task is idempotent — it is skipped once `~/.cargo/bin/rustc` exists). You can also install Rust via Nix instead and delete this task.

**`infra-sync-all` fails: `git pull` asks for a password**
Your `~/.git-credentials` is missing or the token is invalid. Re-run `setup.sh` (it recreates the file), or write the token again:

```bash
echo "https://oauth2:<TOKEN>@github.com" > ~/.git-credentials
chmod 600 ~/.git-credentials
```

**My NAS shares don't mount**
Check the mount anchor directories exist (`/mnt/nas/nfs`, `/mnt/nas/smb`) and that the `.mount`/`.automount` units are active: `systemctl list-units | grep mnt-nas`. Then `ls /mnt/nas/nfs` to trigger the automount. Verify the share addresses in `host_vars/all/vars.yml` match your NAS.

**Rollback / teardown**
Ansible is idempotent — it converges *towards* the declared state but won't uninstall packages on its own. To revert a change, edit the repository, push, and re-apply. To fully remove a piece of software, remove it from the playbook (or Nix) and purge it manually on the machine; Nix rolls back easily with `home-manager generations` + `home-manager switch --generation N`.

---

## Extension Ideas

- **Sway workspace rules** — pin apps to workspaces and add keybinds in `nix/modules/sway.nix` (`config.keybindings`, `config.output`).
- **Waybar modules** — system tray, network, battery (laptop), clock in `programs.waybar` settings inside `nix/modules/sway.nix`.
- **Backups** — a `restic`/`borg` Home Manager service or a cron-based Ansible task for `/home` → your NAS.
- **More Nix modules** — split `sway.nix`/`shell.nix` further (e.g., `editors.nix`, `dev.nix`) and import them in `home.nix`.
- **Per-machine secrets** — per-host vault files for hosts with different WiFi/credentials.
