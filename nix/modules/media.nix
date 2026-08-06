{ config, pkgs, ... }:

{
  # Media playback and image editing.
  home.packages = with pkgs; [
    # Playback
    mpv
    vlc

    # Image editing / conversion
    gimp
    imagemagick
    inkscape
  ];
}