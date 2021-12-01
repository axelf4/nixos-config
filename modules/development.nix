{config, pkgs, lib, ...}:
let
  cfg = config.development;
in
{
  options = {
    development = {
      enable = lib.mkOption {
        default = false;
        type = lib.types.bool;
        description = ''
          Whether to enable an environment with some development tools.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      gdb rr
      rustfmt rust-analyzer
      nodePackages.prettier nodePackages.typescript-language-server
      black
      nodePackages.purty # PureScript formatter
      shellcheck
    ];

    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
    };
  };
}
