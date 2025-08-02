{ lib, runCommandLocal, makeWrapper, pipewire, jq }:
runCommandLocal "pw-target"
  { nativeBuildInputs = [ makeWrapper ]; }
  ''
  makeWrapper ${./pw-target} $out/bin/pw-target \
    --prefix PATH : ${lib.makeBinPath [ pipewire jq ]}
  ''
