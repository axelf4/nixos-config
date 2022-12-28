{ lib, runCommandLocal, makeWrapper, curl }:
runCommandLocal "pastebin"
  { nativeBuildInputs = [ makeWrapper ]; }
  ''
  makeWrapper ${./pastebin} $out/bin/pastebin \
    --prefix PATH : ${lib.makeBinPath [ curl ]}
  ''
