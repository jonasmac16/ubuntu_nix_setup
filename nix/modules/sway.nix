{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    foot
    wofi
    waybar
    mako
  ];

  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = "Mod4";
      terminal = "foot";
      menu = "wofi --show drun";
      bars = [];
      startup = [
        { command = "waybar"; }
        { command = "mako"; }
      ];
    };
  };

  programs.waybar.enable = true;
}
