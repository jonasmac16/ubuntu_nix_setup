{ config, pkgs, ... }:

{
  # Packages and settings specific to the workstation.
  # Applied only when this machine's hostname is `workstation`.
  home.packages = with pkgs; [
    # e.g. vlc
    # e.g. gimp
  ];
}
