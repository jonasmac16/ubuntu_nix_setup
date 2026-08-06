{ config, pkgs, ... }:

{
  # Backup / sync tooling.
  # rsync covers local and LAN copies; rclone covers remote storage
  # (cloud/SFTP) and is fully scriptable for scheduled jobs. Actual backup
  # jobs are left to you — see README "Extension ideas" if you want them as
  # Home Manager services or systemd timers.
  home.packages = with pkgs; [
    rsync
    rclone
  ];
}
