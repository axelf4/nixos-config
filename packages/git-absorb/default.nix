{ lib, runCommandLocal }: runCommandLocal "git-absorb" {} ''
  mkdir -p $out/bin
  cp '${./git-absorb}' $out/bin/git-absorb
''
