{ lib, runCommandLocal, makeWrapper, curl, jq }:
runCommandLocal "open-csb-door"
  { nativeBuildInputs = [ makeWrapper ]; }
  ''
  makeWrapper ${./open-csb-door} $out/bin/open-csb-door \
    --prefix PATH : ${lib.makeBinPath [ curl jq ]}
  ''
