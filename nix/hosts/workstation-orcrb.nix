{ config, pkgs, ... }:

{
  _module.args.keyboardLayout = "us,gb";

  # Packages and settings specific to the workstation.
  # Applied only when this machine's hostname is `workstation-orcrb`.
  home.packages = with pkgs; [
    # e.g. vlc
    # e.g. gimp
  ];
}
