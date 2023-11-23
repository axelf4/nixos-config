# Raspberry Pi 4 Model B
{ config, pkgs, nixos-hardware, ... }:

{
  imports = [ nixos-hardware.nixosModules.raspberry-pi-4 ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  boot.tmp.useTmpfs = true;

  system.stateVersion = "22.05";
}
