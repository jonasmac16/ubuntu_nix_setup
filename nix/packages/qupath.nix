{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
, gtk3
, glib
, gdk-pixbuf
, cairo
, pango
, atk
, libGL
, fontconfig
, freetype
, zlib
, libpng
, libjpeg
, alsa-lib
, openslide
, libxkbcommon
, libx11
, libxext
, libxrender
, libxtst
, libxi
, libxt
, libxfixes
, libxrandr
, libxcursor
, libxxf86vm
}:

# QuPath is shipped by the upstream project as a jpackage bundle: a native
# launcher (ELF) plus a bundled JRE and all application jars. It is not
# packaged in nixpkgs, so we repackage the official binary. Version bumps are
# manual: update `version` and the `sha256` below (get it via
# `nix-prefetch-url <tarball-url>`).
stdenv.mkDerivation (finalAttrs: {
  pname = "qupath";
  version = "0.7.0";

  src = fetchurl {
    url = "https://github.com/qupath/qupath/releases/download/v${finalAttrs.version}/QuPath-v${finalAttrs.version}-Linux.tar.xz";
    sha256 = "165e27a0731d58ba039e9d0d34a54acf896bb92e81922370df295cb85418ce53";
  };

  sourceRoot = "QuPath";

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    zlib
    fontconfig
    freetype
    libGL
    alsa-lib
    libx11
    libxext
    libxrender
    libxtst
    libxi
    libxt
    libxfixes
    libxrandr
    libxcursor
    libxxf86vm
  ];

  dontStrip = true;

  # The jpackage launcher resolves its app dir from its own path
  # (dirname(dirname($exe)) + /lib/app). Installing the unpacked image under
  # $out/lib/qupath keeps the stock layout, so the launcher finds the bundled
  # JRE, config, and jars; the wrapper below is the only `bin` entry point.
  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/qupath
    cp -a . $out/lib/qupath/
    chmod -R u+w $out/lib/qupath
    runHook postInstall
  '';

  postFixup = ''
    makeWrapper $out/lib/qupath/bin/QuPath $out/bin/qupath \
      --prefix LD_LIBRARY_PATH : "${
        lib.makeLibraryPath [
          gtk3 glib gdk-pixbuf cairo pango atk
          libGL
          alsa-lib
          fontconfig freetype zlib libpng libjpeg
          openslide
          libxkbcommon
          libx11 libxext libxrender libxtst libxi
          libxt libxfixes libxrandr libxcursor libxxf86vm
          stdenv.cc.cc.lib
        ]
      }"
  '';

  meta = with lib; {
    description = "Open-source software for digital pathology and whole slide image analysis";
    homepage = "https://qupath.readthedocs.io/";
    changelog = "https://github.com/qupath/qupath/releases";
    license = licenses.gpl3Plus;
    mainProgram = "qupath";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
})
