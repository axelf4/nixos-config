{ config, pkgs, lib, ... }:
let
  cfg = config.development;
in {
  options.development = {
    enable = lib.mkEnableOption "a development environment";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      gdb rr
      rustfmt rust-analyzer
      nodePackages.prettier nodePackages.typescript-language-server
      black
      shellcheck
      hunspell
      gfm-preview
      texlive-nix-pm
      (callPackage ../packages/pastebin {})
    ];
    environment.variables.DICPATH = lib.makeSearchPath "share/hunspell"
      (with pkgs.hunspellDicts; [ en-us sv-se ]);

    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
    };
  };
}
