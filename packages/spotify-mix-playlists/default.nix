{ lib, runCommandLocal, makeWrapper, curl, jq, dnsutils, netcat }:
runCommandLocal "spotify-mix-playlists"
  { nativeBuildInputs = [ makeWrapper ]; }
  ''
  makeWrapper ${./spotify-mix-playlists} $out/bin/spotify-mix-playlists \
    --prefix PATH : ${lib.makeBinPath [ curl jq dnsutils netcat ]}
  ''