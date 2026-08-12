{ config, pkgs, ... }:

{
  _module.args.keyboardLayout = "gb,us";

  # Packages and settings specific to the laptop.
  # Applied only when this machine's hostname is `laptop-xps`.
  imports = [
    ../modules/obs-studio.nix
  ];

  home.packages = with pkgs; [
    # e.g. powertop
  ];
}
