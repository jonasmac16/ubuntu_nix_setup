{ config, pkgs, ... }:

{
  # Screen recording / streaming. Imported only by laptop-xps.nix because the
  # XPS webcam + screen capture workflow is laptop-specific. Wayland screen
  # sharing is handled by xdg-desktop-portal-wlr (see modules/desktop.nix).
  home.packages = with pkgs; [
    obs-studio
  ];
}
