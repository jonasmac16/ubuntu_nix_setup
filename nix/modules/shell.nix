{ config, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false; # defaults declared explicitly below
    settings."*" = {
      HashKnownHosts = true;
      ForwardX11 = false;
      ServerAliveInterval = 60;
    };
    # Host definitions (hostnames/IPs/users) are secrets: they live in the
    # Ansible vault and are deployed by the playbook to ~/.ssh/config.d/.
    extraConfig = "Include ~/.ssh/config.d/*\n";
  };

  programs.git = {
    enable = true;
    settings = {
      # TODO: set your real name/email or commits will be misattributed.
      # Authentication is SSH-only (the playbook deploys ~/.ssh/id_ed25519).
      user = {
        name = "Your Name";
        email = "you@example.com";
      };
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
    };
  };

  programs.bash = {
    enable = true;
    historyControl = [ "ignoredups" "ignorespace" ];
    shellAliases = {
      infra-apply-system = "ansible-playbook -i ansible/inventory.ini ansible/playbook.yml -l \"$(hostname)\" --ask-become-pass --ask-vault-pass";
      infra-apply-user   = "home-manager switch --impure --flake ~/src/nix-ubuntu-infra#jonas";
      infra-sync-all     = "git pull origin main && infra-apply-system && infra-apply-user";

      infra-commit = "git add -A && git commit -m";
      infra-push   = "git push origin main";
      infra-save   = "git add -A && git commit -m 'wip automated configuration tracking save' && git push origin main";
    };
  };
}
