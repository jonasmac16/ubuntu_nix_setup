{ config, pkgs, ... }:

{
  # Science / bioimaging tooling.
  home.packages = with pkgs; [
    fiji
    # QuPath is built from the official jpackage binary via the flake overlay
    # (see nix/packages/qupath.nix) — it is no longer in nixpkgs.
    qupath
  ];
}
