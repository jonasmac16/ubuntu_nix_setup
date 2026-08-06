{ config, pkgs, ... }:

{
  imports = [
    ./modules/sway.nix
    ./modules/shell.nix
    ./modules/browsers.nix
    ./modules/development.nix
    ./modules/office.nix
    ./modules/media.nix
    ./modules/science.nix
    ./modules/files.nix
    ./modules/security.nix
    ./modules/system.nix
  ];

  home.username = "jonas";
  home.homeDirectory = "/home/jonas";
  home.stateVersion = "26.05";

  # Packages installed on every machine.
  home.packages = with pkgs; [
    htop
    ripgrep
    fzf
    firefox
  ];

  # NAS SMB/NFS mounts are currently DISABLED (see ansible/playbook.yml).
  # Uncomment these symlinks when the NAS mounts are enabled.
  home.file = {
    # "NAS-NFS" = {
    #   source = config.lib.file.mkOutOfStoreSymlink "/mnt/nas/nfs";
    # };
    # "NAS-SMB" = {
    #   source = config.lib.file.mkOutOfStoreSymlink "/mnt/nas/smb";
    # };
  };
}
