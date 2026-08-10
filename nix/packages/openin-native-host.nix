{ lib, stdenv, fetchFromGitHub, makeWrapper, nodejs }:

# Native messaging host (com.add0n.node) used by the "Open in Firefox" Chromium
# extension (andy-portmen). The extension sends URLs to this stdio host over
# Chrome's native-messaging protocol and it spawns the target browser.
# Pinned to upstream native-client v1.1.2; only host.js + messaging.js are
# needed at runtime (host.js is the message pump, messaging.js implements the
# length-prefixed framing; config.js is only used by the upstream installer).
stdenv.mkDerivation rec {
  pname = "openin-native-host";
  version = "1.1.2";

  src = fetchFromGitHub {
    owner = "andy-portmen";
    repo = "native-client";
    rev = "v${version}";
    sha256 = "179p8szfxv748z90iv1rghkkypbcxi1acy4aywyskv6bvil3r8ib";
  };

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [ nodejs ];

  dontPatchELF = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/openin"
    install -m 0644 host.js messaging.js "$out/share/openin/"
    makeWrapper "${nodejs}/bin/node" "$out/share/openin/run.sh" \
      --add-flags "$out/share/openin/host.js"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Native messaging host for the Open in Firefox browser extension";
    homepage = "https://github.com/andy-portmen/native-client";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
