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

  # ZotMoov plugin (Zotfile's Zotero 7 successor): auto-files new attachments
  # into the complete library (01_zotero_library) by first author then year, and
  # adds a right-click "Copy to Reading Library" menu entry that copies the
  # selected item's PDF into the reading library (02_zotero_reading_library) and
  # tags it "reading". Pinned + checksum-verified; Zotero 7 loads a packed .xpi
  # placed in the profile extensions dir on the next launch.
  home.activation.installZotmoov = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if pgrep -x zotero >/dev/null 2>&1; then
      echo "[zotmoov] Zotero is running; close it and re-run the switch to install/configure ZotMoov."
      exit 0
    fi

    ZOTMOOV_VERSION="1.2.32"
    ZOTMOOV_SHA256="7770dc2c62d2aaab2662fd7402afadd058387bff69578481ac039bfc050ecc2b"
    ZOTMOOV_URL="https://github.com/wileyyugioh/zotmoov/releases/download/$ZOTMOOV_VERSION/zotmoov-$ZOTMOOV_VERSION-fx.xpi"

    PROFILE=""
    for cand in "$HOME/Zotero/prefs.js" "$HOME/.zotero/prefs.js" "$HOME"/.zotero/zotero/*/prefs.js "$HOME"/.zotero/Profiles/*/prefs.js; do
      [ -f "$cand" ] && PROFILE="$(${pkgs.coreutils}/bin/dirname "$cand")" && break
    done
    if [ -z "$PROFILE" ]; then
      echo "[zotmoov] No Zotero profile found yet; plugin + prefs are applied on the next switch after Zotero's first launch."
      exit 0
    fi
    echo "[zotmoov] Zotero profile: $PROFILE"

    ${pkgs.coreutils}/bin/mkdir -p "$PROFILE/extensions"
    XPI="$PROFILE/extensions/zotmoov-$ZOTMOOV_VERSION-fx.xpi"
    if [ -f "$XPI" ] && [ "$(${pkgs.coreutils}/bin/sha256sum "$XPI" | ${pkgs.coreutils}/bin/cut -d' ' -f1)" = "$ZOTMOOV_SHA256" ]; then
      echo "[zotmoov] plugin already present and verified"
    else
      echo "[zotmoov] downloading ZotMoov $ZOTMOOV_VERSION ..."
      ${pkgs.curl}/bin/curl -fsSL "$ZOTMOOV_URL" -o "$XPI"
      ACTUAL="$(${pkgs.coreutils}/bin/sha256sum "$XPI" | ${pkgs.coreutils}/bin/cut -d' ' -f1)"
      if [ "$ACTUAL" != "$ZOTMOOV_SHA256" ]; then
        echo "[zotmoov] ERROR: checksum mismatch (got $ACTUAL); refusing to install."
        ${pkgs.coreutils}/bin/rm -f "$XPI"
        exit 1
      fi
    fi

    # Stage a fallback copy for manual install if Zotero refuses to sideload.
    ${pkgs.coreutils}/bin/mkdir -p "$HOME/.local/share/zotmoov"
    ${pkgs.coreutils}/bin/cp -f "$XPI" "$HOME/.local/share/zotmoov/zotmoov-$ZOTMOOV_VERSION-fx.xpi"
    echo "[zotmoov] installed; restart Zotero. Fallback if it doesn't load: Tools -> Plugins -> Install Add-on From File -> $HOME/.local/share/zotmoov/zotmoov-$ZOTMOOV_VERSION-fx.xpi"

    # Force Zotero's AddonManager to re-scan the extensions directory.
    ${pkgs.gnused}/bin/sed -i -E '/extensions\.last(AppBuildId|AppVersion|PlatformVersion)/d' "$PROFILE/prefs.js"

    ZBASE01="${config.home.homeDirectory}/OneDrive/shared_work/xx_bibliography/01_zotero_library"
    ZBASE02="${config.home.homeDirectory}/OneDrive/shared_work/xx_bibliography/02_zotero_reading_library"

    add_pref() {
      local key="$1" value="$2"
      if ! grep -qF "$key" "$PROFILE/prefs.js"; then
        echo "user_pref(\"$key\", $value);" >> "$PROFILE/prefs.js"
        echo "[zotmoov] seeded pref $key"
      fi
    }

    add_pref 'extensions.zotmoov.dst_dir' "\"$ZBASE01\""
    add_pref 'extensions.zotmoov.enable_automove' 'true'
    add_pref 'extensions.zotmoov.file_behavior' '"move"'
    add_pref 'extensions.zotmoov.enable_subdir_move' 'true'
    add_pref 'extensions.zotmoov.subdirectory_string' '"{%a}/{%y}"'
    add_pref 'extensions.zotmoov.allowed_fileext' '["pdf","epub","docx","djvu"]'
    add_pref 'extensions.zotmoov.delete_files' 'false'
    add_pref 'extensions.zotmoov.custom_menu_items' "{\"Copy to Reading Library\":[{\"command_name\":\"copy\",\"directory\":\"$ZBASE02\",\"enable_customdir\":true,\"enable_subdir\":true},{\"command_name\":\"addtag\",\"tag\":\"reading\"}]}"
  '';

  # Better BibTeX plugin: exports citations / bibliographies as BibTeX or BibLaTeX
  # (e.g. for Pandoc/LaTeX) and provides citation-key automation. Installed the
  # same way as ZotMoov: a packed .xpi is dropped into the profile extensions
  # dir; Zotero loads it on the next launch. v9.x requires Zotero 8+ (the locked
  # nixpkgs ships Zotero 9). No prefs are seeded; configure in the plugin's
  # preferences after the first launch.
  home.activation.installBBT = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if pgrep -x zotero >/dev/null 2>&1; then
      echo "[bbt] Zotero is running; close it and re-run the switch to install Better BibTeX."
      exit 0
    fi

    BBT_VERSION="9.0.55"
    BBT_SHA256="2d914ebb174c2c590ecff741a6903f1979065b42740f301d938ec2cb6c03e4d6"
    BBT_URL="https://github.com/retorquere/zotero-better-bibtex/releases/download/v$BBT_VERSION/zotero-better-bibtex-$BBT_VERSION.xpi"

    PROFILE=""
    for cand in "$HOME/Zotero/prefs.js" "$HOME/.zotero/prefs.js" "$HOME"/.zotero/zotero/*/prefs.js "$HOME"/.zotero/Profiles/*/prefs.js; do
      [ -f "$cand" ] && PROFILE="$(${pkgs.coreutils}/bin/dirname "$cand")" && break
    done
    if [ -z "$PROFILE" ]; then
      echo "[bbt] No Zotero profile found yet; Better BibTeX is installed on the next switch after Zotero's first launch."
      exit 0
    fi
    echo "[bbt] Zotero profile: $PROFILE"

    ${pkgs.coreutils}/bin/mkdir -p "$PROFILE/extensions"
    XPI="$PROFILE/extensions/zotero-better-bibtex-$BBT_VERSION.xpi"
    if [ -f "$XPI" ] && [ "$(${pkgs.coreutils}/bin/sha256sum "$XPI" | ${pkgs.coreutils}/bin/cut -d' ' -f1)" = "$BBT_SHA256" ]; then
      echo "[bbt] plugin already present and verified"
    else
      echo "[bbt] downloading Better BibTeX $BBT_VERSION ..."
      ${pkgs.curl}/bin/curl -fsSL "$BBT_URL" -o "$XPI"
      ACTUAL="$(${pkgs.coreutils}/bin/sha256sum "$XPI" | ${pkgs.coreutils}/bin/cut -d' ' -f1)"
      if [ "$ACTUAL" != "$BBT_SHA256" ]; then
        echo "[bbt] ERROR: checksum mismatch (got $ACTUAL); refusing to install."
        ${pkgs.coreutils}/bin/rm -f "$XPI"
        exit 1
      fi
    fi

    # Stage a fallback copy for manual install if Zotero refuses to sideload.
    ${pkgs.coreutils}/bin/mkdir -p "$HOME/.local/share/zotero-better-bibtex"
    ${pkgs.coreutils}/bin/cp -f "$XPI" "$HOME/.local/share/zotero-better-bibtex/zotero-better-bibtex-$BBT_VERSION.xpi"
    echo "[bbt] installed; restart Zotero. Fallback if it doesn't load: Tools -> Plugins -> Install Add-on From File -> $HOME/.local/share/zotero-better-bibtex/zotero-better-bibtex-$BBT_VERSION.xpi"

    # Force Zotero's AddonManager to re-scan the extensions directory.
    ${pkgs.gnused}/bin/sed -i -E '/extensions\.last(AppBuildId|AppVersion|PlatformVersion)/d' "$PROFILE/prefs.js"
  '';
}
