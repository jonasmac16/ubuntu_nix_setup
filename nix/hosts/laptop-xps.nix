{ config, pkgs, ... }:

{
  # Packages and settings specific to the laptop.
  # Applied only when this machine's hostname is `thinkpad-x1`.
  home.packages = with pkgs; [
    # e.g. powertop
    # e.g. wl-clipboard
  ];
}
