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
      gfm-preview
      texlive-nix-pm
    ];

    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
    };
  };
}
