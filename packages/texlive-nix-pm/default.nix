{ lib, runCommandLocal, makeWrapper, bash, curl, xz, nix }:
runCommandLocal "texlive-nix-pm"
  { nativeBuildInputs = [ makeWrapper ]; }
  ''
  makeWrapper ${./texlive-nix-pm} $out/bin/texlive-nix-pm \
    --prefix PATH : ${lib.makeBinPath [ bash curl xz nix ]}
  ''
