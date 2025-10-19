{ lib, pkgs, ... }:

{
  networking.networkmanager.enable = lib.mkForce false;
  networking.useDHCP = false;
  networking.interfaces.br0.ipv4.addresses =
    [ { address = "10.0.0.1"; prefixLength = 24; } ];
  networking.bridges.br0.interfaces = [ "end0" ];
  systemd.network.networks."30-end0" = {
    name = "end0";
    DHCP = "yes"; # Request IP address from ISP
  };

  networking.nat = {
    enable = true;
    internalInterfaces = [ "br0" ];
    externalInterface = "end0";
  };

  services.dnsmasq = {
    enable = true;
    settings = {
      bogus-priv = true;
      domain-needed = true;
      expand-hosts = true;
      no-resolv = true;
      no-hosts = true;
      domain = "axelf.se";

      interface = [ "br0" ];
      bind-interfaces = true;

      server = [ "9.9.9.9" "1.1.1.1" ];
      dnssec = true;
      conf-file = "${pkgs.dnsmasq}/share/dnsmasq/trust-anchors.conf";

      dhcp-range = [ "10.0.0.10,10.0.0.254" ];
    };
  };
  systemd.services.dnsmasq = {
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];
  };

  networking.firewall = {
    interfaces.br0 = {
      allowedUDPPorts = [
        53 # DNS
        67 # DHCP
      ];
      allowedTCPPorts = [ 53 ];
    };
  };

  services.hostapd = {
    enable = true;
    radios.wlan0 = {
      countryCode = "SE";
      band = "5g";
      networks.wlan0 = {
        ssid = "Suzanne Router";
        authentication.mode = "wpa2-sha1";
        authentication.wpaPasswordFile = "/etc/wlan0-password";
        settings = { bridge = "br0"; wmm_enabled = true; };
      };
    };
  };
}
