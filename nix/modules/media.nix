{ config, pkgs, ... }:

{
  # Media playback.
  home.packages = with pkgs; [
    mpv
    vlc
  ];
}