{ lib, runCommandLocal }: runCommandLocal "git-absorb" {} ''
  install -D ${./git-absorb} $out/bin/git-absorb
''
