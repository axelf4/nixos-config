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
      clang-tools # Provides the clangd language server
      rustfmt rust-analyzer
      nodePackages.prettier typescript-language-server
      black pyright
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

    # Keep build-time dependencies.
    #
    # Marks outputs of derivations (including those from which rooted
    # store paths were built, due to keep-derivations).
    nix.settings.keep-outputs = true;

    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
    };
  };
}
