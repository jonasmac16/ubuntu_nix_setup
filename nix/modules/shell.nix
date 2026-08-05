{ config, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "nas-endpoint" = {
        hostname = "192.168.1.100";
        user = "storage_admin";
        identityFile = "~/.ssh/id_ed25519";
      };
    };
  };

  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "you@example.com";
    extraConfig = {
      credential.helper = "store --file ~/.git-credentials";
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
    };
  };

  programs.bash = {
    enable = true;
    historyControl = [ "ignoredups" "ignorespace" ];
    shellAliases = {
      infra-apply-system = "ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --ask-become-pass --ask-vault-pass";
      infra-apply-user   = "home-manager switch";
      infra-sync-all     = "git pull origin main && infra-apply-system && infra-apply-user";

      infra-commit = "git add -A && git commit -m";
      infra-push   = "git push origin main";
      infra-save   = "git add -A && git commit -m 'wip automated configuration tracking save' && git push origin main";
    };
  };
}
