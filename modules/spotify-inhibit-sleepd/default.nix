{ config, pkgs, lib, ... }:

let
  package = pkgs.stdenv.mkDerivation {
    pname = "spotify-inhibit-sleepd";
    version = "1.0.0";
    src = ./.;
    nativeBuildInputs = with pkgs; [ pkg-config cmake ];
    buildInputs = with pkgs; [ glib ];
  };

  cfg = config.services.spotify-inhibit-sleepd;
in {
  options.services.spotify-inhibit-sleepd = {
    enable = lib.mkEnableOption "daemon that blocks sleep when Spotify is playing audio";
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.spotify-inhibit-sleepd = {
      wantedBy = [ "graphical-session.target" ];
      after = [ "dbus.socket" ];
      requisite = [ "dbus.socket" ];
      description = "Inhibit sleep when Spotify is playing audio";
      serviceConfig = {
        Type = "exec";
        ExecStart = "${package}/bin/spotify-inhibit-sleepd";
        Restart = "on-failure";
      };
    };
  };
}
