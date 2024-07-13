{ config, pkgs, lib, ... }:
let
  cfg = config.development;
in {
  options.development = {
    enable = lib.mkEnableOption "a development environment";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      config.boot.kernelPackages.perf

      gdb rr
      clang-tools
      rustfmt rust-analyzer
      nodePackages.prettier nodePackages.typescript-language-server
      black
      shellcheck
      hunspell
      gfm-preview
      git-absorb
      texlive-nix-pm
      (callPackage ../packages/pastebin {})
    ];
    environment.variables.DICPATH = lib.makeSearchPath "share/hunspell"
      (with pkgs.hunspellDicts; [ en-us sv-se ]);

    # Allow kernel profiling for all users (needed by rr)
    boot.kernel.sysctl."kernel.perf_event_paranoid" = 1;

    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
    };
  };
}
