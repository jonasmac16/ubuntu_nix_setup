{ config, pkgs, ... }:

{
  # File manager + network share access.
  # SMB/NFS client tools (cifs-utils, nfs-common) are installed system-wide by
  # the Ansible playbook; gvfs lets Thunar browse smb shares; sshfs is the
  # FUSE-based SSH client.
  home.packages = with pkgs; [
    thunar
    thunar-volman
    thunar-archive-plugin
    thunar-media-tags-plugin
    tumbler
    gvfs
    sshfs
  ];
}