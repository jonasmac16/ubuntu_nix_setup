{ config, pkgs, ... }:

{
  # Science / bioimaging tooling.
  home.packages = with pkgs; [
    fiji
    qupath
  ];
}