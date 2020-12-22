# Raspberry Pi 4 Model B
{ config, pkgs, ... }:

{
  # Installed on top of the disk image
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-label/NIXOS_BOOT";
      fsType = "vfat";
    };
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };

  boot.loader.grub.enable = false;
  boot.loader.raspberryPi.enable = true;
  boot.loader.raspberryPi.version = 4;
  # Mainline kernel does not work yet
  boot.kernelPackages = pkgs.linuxPackages_rpi4;

  boot.kernelParams = [
    # ttyAMA0 is the serial console broken out to the GPIO
    "console=ttyAMA0,115200"
    "console=tty1"
  ];

  # Required for the wireless firmware
  hardware.enableRedistributableFirmware = true;

  system.stateVersion = "21.03";
}
