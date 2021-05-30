{ lib, runCommandLocal, makeWrapper, xdotool, xclip, xorg }:
runCommandLocal "edit-selection"
  { nativeBuildInputs = [ makeWrapper ]; }
  ''
  makeWrapper ${./edit-selection} $out/bin/edit-selection \
    --prefix PATH : ${lib.makeBinPath [ xdotool xclip xorg.xprop ]}
  ''
