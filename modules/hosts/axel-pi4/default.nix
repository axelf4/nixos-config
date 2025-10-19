# Raspberry Pi 4 Model B
{
  imports = [ ./router.nix ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  boot = {
    initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };

    tmp.useTmpfs = true;
  };
  hardware.enableRedistributableFirmware = true;

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "23.11";
}
