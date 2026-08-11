{ config, pkgs, ... }:

{
  # Science / bioimaging tooling.
  home.packages = with pkgs; [
    fiji
    # QuPath is built from the official jpackage binary via the flake overlay
    # (see nix/packages/qupath.nix) — it is no longer in nixpkgs.
    qupath

    # RStudio + R, with a curated CRAN package set baked in via the wrapper
    # (also pulls in R base + nixpkgs' recommended R packages).
    (rstudioWrapper.override {
      packages = (with rPackages; [
        tidyverse
        ggplot2
        data_table
        dplyr
        tidyr
        knitr
        rmarkdown
        readxl
        stringr
        lubridate
      ]);
    })
  ];
}
