{ config, pkgs, ... }:

{
  # Standalone password manager desktop apps. Browser add-ons live in
  # modules/browsers.nix.
  home.packages = with pkgs; [
    proton-pass
    bitwarden-desktop
  ];
}