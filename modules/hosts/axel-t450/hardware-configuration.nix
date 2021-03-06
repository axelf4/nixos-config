# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{
  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/0d22ca88-5409-407a-852e-d3565d7b4490";
      fsType = "ext4";
    };

  fileSystems."/nix/store" =
    { device = "/nix/store";
      fsType = "none";
      options = [ "bind" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/58F8-E2D5";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/d429d3f1-45d8-4ef9-89e0-8084bee3d9ec"; }
    ];

  nix.maxJobs = lib.mkDefault 4;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
