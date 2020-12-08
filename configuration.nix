{ config, pkgs, ... }:

{
  imports = [
    ./modules/kdeconnect.nix
    ./hardware-configuration.nix # Include the results of the hardware scan.
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.extraModprobeConfig = ''
    options snd slots=snd-hda-intel
  '';

  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = true;
    pulseaudio.enable = true;
    bluetooth.enable = true;
  };
  sound.enable = true;

  networking.hostName = "AxelsDator";
  networking.networkmanager.enable = true;

  # Hibernate on low battery level
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", ATTR{capacity}=="[0-5]", RUN+="${pkgs.systemd}/bin/systemctl hibernate"
  '';

  # Select internationalisation properties.
  console.useXkbConfig = true;
  time.timeZone = "Europe/Stockholm";

  nixpkgs.config.allowUnfree = true;
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    emacs-nox tmux curl git ripgrep firefox alacritty spotify
    xclip # System clipboard support in terminal Emacs
    (callPackage ./packages/spotify-mix-playlists {})
  ];
  environment.variables = {
    EDITOR = "emacs"; VISUAL = "$EDITOR";
    MOZ_USE_XINPUT2 = "1";
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # List services that you want to enable:
  # services.openssh.enable = true; # Enable the OpenSSH daemon.
  services.printing.enable = true; # Enable CUPS to print documents.
  services.tlp.enable = true;

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    layout = "se";
    xkbOptions = "caps:escape,shift:both_capslock";
    autoRepeatDelay = 200;
    autoRepeatInterval = 100;
  
    # Enable touchpad support.
    libinput = {
      enable = true;
      naturalScrolling = true;
      tappingDragLock = false; # Quit dragging immediately after release
      # Hack to make options only apply to touchpad
      additionalOptions = ''MatchIsTouchpad "on"'';
    };

    # Enable the KDE Desktop Environment.
    desktopManager.plasma5.enable = true;
  };

  location.provider = "geoclue2";
  services.redshift.enable = true;

  users.mutableUsers = false;
  # Define a user account.
  users.users.axel = {
    isNormalUser = true;
    description = "Axel Forsman";
    extraGroups = [ "wheel" "networkmanager" "video" "docker" "wireshark" ];
    hashedPassword = "$6$SdpjwG9cIGv$yBZ2HQ7gTNkEg54UW2uM7nIZ5ARv0GNNw/IVDLszolz8pz/fVfNJaW2ktIBMcB30HGOkGKn4koMfKocTjMHNE.";
  };

  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?
}

