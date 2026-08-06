{ config, pkgs, ... }:

{
  # Science / bioimaging tooling.
  home.packages = with pkgs; [
    fiji
    # qupath was removed from nixpkgs (project archived upstream).
    # Re-add when/if it returns, or install the .deb manually via
    # the Ansible playbook (Section B).
  ];
}