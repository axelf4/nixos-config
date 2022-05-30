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

  programs.steam.enable = true;

  system.stateVersion = "22.05";
}
