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
    ./modules/desktop.nix
    ./modules/backups.nix
  ];

  # NUR overlay. The `nur` channel is added by setup.sh; this overlay exposes it
  # as `pkgs.nur`, which browsers.nix needs for the Firefox add-ons. Without it
  # the config would fail at evaluation time with "attribute 'nur' missing".
  nixpkgs.overlays = [
    (final: prev: {
      nur = import <nur> { pkgs = prev; };
    })
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
