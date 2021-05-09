{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix # Include the results of the hardware scan
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.extraModprobeConfig = ''
    options snd slots=snd-hda-intel
  '';

  hardware.cpu.intel.updateMicrocode = true;

  graphical.enable = true;
  development.enable = true;

  services.tlp.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "20.03";
}
