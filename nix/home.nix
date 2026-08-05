{ config, pkgs, ... }:

{
  imports = [
    ./modules/sway.nix
    ./modules/shell.nix
  ];

  home.username = "your_username";
  home.homeDirectory = "/home/your_username";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    htop
    ripgrep
    fzf
    firefox
  ];

  home.file = {
    "NAS-NFS" = {
      source = config.lib.file.mkOutOfStoreSymlink "/mnt/nas/nfs";
    };
    "NAS-SMB" = {
      source = config.lib.file.mkOutOfStoreSymlink "/mnt/nas/smb";
    };
  };
}
