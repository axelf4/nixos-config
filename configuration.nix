{ config, pkgs, ... }:

{
  imports = [
    ./modules/graphical.nix
    ./modules/development.nix
    ./modules/kdeconnect.nix
  ];

  hardware = {
    enableRedistributableFirmware = true;
    pulseaudio.enable = true;
    bluetooth.enable = true;
  };
  sound.enable = true;
  location.provider = "geoclue2";
  networking.networkmanager.enable = true;
  # Make strongSwan aware of NetworkManager config (see NixOS/nixpkgs#64965)
  environment.etc."ipsec.secrets".text = "include ipsec.d/ipsec.nm-l2tp.secrets";

  # Select internationalisation properties
  i18n = {
    defaultLocale = "sv_SE.UTF-8";
    extraLocaleSettings = { LC_MESSAGES = "en_US.UTF-8"; };
  };
  console.useXkbConfig = true;
  services.xserver = {
    layout = "se";
    xkbOptions = "caps:escape,shift:both_capslock";
  };
  time.timeZone = "Europe/Stockholm";

  nixpkgs.config.allowUnfree = true;
  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    emacs-nox tmux curl git ripgrep
    zip unzip

    (callPackage ./packages/spotify-mix-playlists {})
    (callPackage ./packages/open-csb-door {})
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  # Unlock GnuPG keys on login
  # (The login PAM config gets included by display manager files.)
  security.pam.services.login.gnupg = {
    enable = true;
    storeOnly = true;
  };
  programs.ssh.knownHosts = {
    "github.com" = {
      hostNames = [ "github.com" ];
      publicKeyFile = ./pubkeys/github_ssh_host_rsa_key.pub;
    };
    chalmers = {
      hostNames = [ "remote11.chalmers.se" "remote12.chalmers.se" ];
      publicKeyFile = ./pubkeys/chalmers_ssh_host_ed25519_key.pub;
    };
  };
  services.openssh.enable = true; # Enable the OpenSSH daemon

  services.printing.enable = true; # Enable CUPS to print documents

  users.mutableUsers = false;
  # Define a user account
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
}
