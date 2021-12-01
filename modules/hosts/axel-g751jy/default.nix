{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix # Include the results of the hardware scan
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.cpu.intel.updateMicrocode = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  services.tlp.enable = true;

  graphical.enable = true;
  development.enable = true;

  # Wine and Steam
  environment.systemPackages = with pkgs; [
    wineWowPackages.stable
  ];
  programs.steam.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "20.09";
}
