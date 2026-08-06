{ config, pkgs, ... }:

{
  # System utilities: Wayland display-settings GUI and Logitech device manager.
  # wdisplays ships no declarative config file — set displays interactively and
  # it persists through the compositor. Launch it from the launcher (wofi) or a
  # terminal so you can change display settings on the fly.
  home.packages = with pkgs; [
    wdisplays
    solaar
  ];
}