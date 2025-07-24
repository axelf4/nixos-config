{ lib, runCommandLocal }: runCommandLocal "backlightctl" {} ''
  install -D ${./backlightctl} $out/bin/backlightctl
''
