{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix # Include the results of the hardware scan
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelParams = [
    "acpi_osi=" # Fix brightness keys
  ];

  services.xserver.videoDrivers = [ "nvidia" ];

  services.tlp.enable = true;

  graphical.enable = true;
  development.enable = true;

  # Wine and Steam
  environment.systemPackages = with pkgs; [
    wineWowPackages.stable
  ];
  programs.steam.enable = true;

  system.stateVersion = "22.05";
}
