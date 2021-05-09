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
      rustfmt
      black
      nodePackages.purty # PureScript formatter
      shellcheck
    ];
  };
}
