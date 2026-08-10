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

  # Zotero linked attachments on OneDrive. Linked files live in the
  # 01_zotero_library folder (the Linked Attachment Base Directory); the
  # 02_zotero_reading_library folder is for PDFs you copy onto a tablet for
  # reading — both sync via the OneDrive client. The database
  # (~/Zotero/zotero.sqlite) stays local and keeps syncing metadata with
  # zotero.org; linked files are never uploaded there.
  home.file = {
    "OneDrive/shared_work/xx_bibliography/01_zotero_library/.gitkeep".text = "";
    "OneDrive/shared_work/xx_bibliography/02_zotero_reading_library/.gitkeep".text = "";
  };

  # Seed the Linked Attachment Base Directory pref into Zotero's prefs.js.
  # Zotero rewrites prefs.js at runtime, so this only appends when the pref is
  # missing and skips entirely while Zotero is running (set it manually in
  # Settings -> Advanced -> Files & Folders in that case, or re-run the switch
  # after Zotero's first launch).
  home.activation.zoteroLinkedBaseDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ZBASE="${config.home.homeDirectory}/OneDrive/shared_work/xx_bibliography/01_zotero_library"
    if pgrep -x zotero >/dev/null 2>&1; then
      echo "[warn] Zotero is running; set Linked Attachment Base Directory manually in Settings -> Advanced -> Files & Folders."
    else
      for pf in "$HOME/.zotero/zotero/"*"/prefs.js" "$HOME/.zotero/Profiles/"*"/prefs.js"; do
        [ -f "$pf" ] || continue
        if ! grep -q 'extensions.zotero.baseAttachmentPath' "$pf"; then
          echo "user_pref(\"extensions.zotero.baseAttachmentPath\", \"$ZBASE\");" >> "$pf"
          echo "[zotero] Linked Attachment Base Directory -> $ZBASE ($pf)"
        fi
      done
    fi
  '';
}
