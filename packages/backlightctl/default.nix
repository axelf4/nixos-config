{ lib, runCommandLocal }: runCommandLocal "backlightctl" {} ''
  mkdir -p $out/bin
  cp ${./backlightctl} $out/bin/backlightctl
''
