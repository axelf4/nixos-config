{ config, pkgs, ... }:

{
  imports = [
    modules/graphical.nix
    modules/development.nix
  ];

  boot.loader.systemd-boot.editor = false;
  hardware.bluetooth.enable = true;
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
    layout = "se-custom";
    xkbOptions = "caps:escape,shift:both_capslock,grp:ctrls_toggle";
    extraLayouts.se-custom = {
      description = "SE layout with customizations";
      languages = [ "swe" "eng" ];
      symbolsFile = xkb/symbols/se-custom;
    };
  };
  time.timeZone = "Europe/Stockholm";

  # Use block cursor in the Linux VT. The VGA standard offers no way
  # to alter the cursor blink rate, so make it invisible and emulate
  # in software.
  boot.kernelParams = [ "vt.cur_default=0x000071" ];
  # Disable blinking entirely in the the Linux Framebuffer Console,
  # since e.g. text editors override the default set above.
  systemd.tmpfiles.rules = [ "w /sys/class/graphics/fbcon/cursor_blink - - - - 0" ];

  nixpkgs.config.allowUnfree = true;
  environment.defaultPackages = [];
  programs.nano.syntaxHighlight = false; # Avoid dependency on nano (#195795)
  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    emacs-nox
    tmux curl git ripgrep
    zip unzip
    rsync strace

    (callPackage packages/spotify-mix-playlists {})
    (callPackage packages/open-csb-door {})
  ];
  environment.variables.EDITOR = "${pkgs.ed}/bin/ed";

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
    "github.com".publicKeyFile = pubkeys/github_ssh_host_ed25519_key.pub;
    "gitlab.com".publicKeyFile = pubkeys/gitlab_ssh_host_ed25519_key.pub;
    chalmers = {
      hostNames = [ "remote11.chalmers.se" "remote12.chalmers.se" ];
      publicKeyFile = pubkeys/chalmers_ssh_host_ed25519_key.pub;
    };
  };
  # Enable the OpenSSH daemon
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };

  services.printing.enable = true; # Enable CUPS to print documents

  users.mutableUsers = false;
  # Define a user account
  users.users.axel = {
    isNormalUser = true;
    description = "Axel Forsman";
    extraGroups = [ "wheel" "networkmanager" "video" "wireshark" ];
    hashedPassword = "$6$SdpjwG9cIGv$yBZ2HQ7gTNkEg54UW2uM7nIZ5ARv0GNNw/IVDLszolz8pz/fVfNJaW2ktIBMcB30HGOkGKn4koMfKocTjMHNE.";
  };

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];

    # Binary cache for Haskell.nix
    substituters = [
      "https://cache.iog.io"
    ];
    trusted-public-keys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
    ];
  };
}
