{ config, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    settings = {
      "nas-endpoint" = {
        hostname = "192.168.1.100";
        user = "storage_admin";
        identityFile = "~/.ssh/id_ed25519";
      };
    };
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
      infra-apply-user   = "home-manager switch";
      infra-sync-all     = "git pull origin main && infra-apply-system && infra-apply-user";

      infra-commit = "git add -A && git commit -m";
      infra-push   = "git push origin main";
      infra-save   = "git add -A && git commit -m 'wip automated configuration tracking save' && git push origin main";
    };
  };
}
