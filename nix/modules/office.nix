{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    libreoffice
    obsidian
    zotero
    yed

    # Java runtime for Zotero's LibreOffice integration and yEd.
    temurin-jre-bin-17

    # British (-ise spelling) + American English spelling dictionaries.
    # LibreOffice (via hunspell) picks these up through DICPATH below.
    # Note: nixpkgs splits British English into en_GB-ise / en_GB-ize.
    hunspellDicts.en_GB-ise
    hunspellDicts.en_US
  ];

  # Point hunspell (used by LibreOffice for spell checking) at the declared
  # dictionaries so en_GB / en_US are selectable in Tools -> Options -> Language.
  home.sessionVariables.DICPATH = "${pkgs.hunspellDicts.en_GB-ise}/share/hunspell:${pkgs.hunspellDicts.en_US}/share/hunspell";

  # Auto-install Zotero's bundled LibreOffice add-in (Zotero_LibreOffice_Integration.oxt)
  # into the user LibreOffice profile via unopkg. Requires a JRE (installed above);
  # after first switch, set the JRE in LibreOffice: Tools -> Options -> Advanced.
  home.activation.installZoteroLO = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    oxt=$(${pkgs.findutils}/bin/find ${pkgs.zotero} -name "Zotero_LibreOffice_Integration.oxt" -print -quit 2>/dev/null || true)
    if [ -n "$oxt" ]; then
      LO_URI="file://$HOME/.config/libreoffice/4/user"
      if ! ${pkgs.libreoffice}/bin/unopkg -env:UserInstallation="$LO_URI" list "$oxt" 2>/dev/null | grep -qi zotero; then
        ${pkgs.libreoffice}/bin/unopkg -env:UserInstallation="$LO_URI" add "$oxt" 2>&1 \
          || echo "[warn] Zotero LibreOffice add-in install failed; install manually via Zotero: Settings -> Cite."
      fi
    else
      echo "[warn] Zotero LibreOffice integration .oxt not found in the zotero package."
    fi
  '';
}