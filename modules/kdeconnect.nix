{config, pkgs, lib, ...}:
let
  cfg = config.services.kdeconnect;
in
{
  options = {
    services.kdeconnect = {
      enable = lib.mkOption {
        default = config.services.xserver.desktopManager.plasma5.enable;
        type = lib.types.bool;
        description = ''
          Connect your computer to your smartphone or tablet.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.kdeconnect ];

    # KDE Connect uses dynamic ports in the range 1714-1764 for UDP and TCP
    networking.firewall.allowedUDPPortRanges = [ {from = 1714; to = 1764;} ];
    networking.firewall.allowedTCPPortRanges = [ {from = 1714; to = 1764;} ];
  };
}
