{ lib, runCommandLocal, makeWrapper, curl, jq, netcat, fswatch }:
runCommandLocal "gfm-preview"
  { nativeBuildInputs = [ makeWrapper ]; }
  ''
  makeWrapper ${./gfm-preview} $out/bin/gfm-preview \
    --prefix PATH : ${lib.makeBinPath [ curl jq netcat fswatch ]}
  ''
