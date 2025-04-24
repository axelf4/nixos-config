{ pkgs, ... }:

let
  run0-sudo-shim = pkgs.writeShellScriptBin "sudo" ''exec run0 "$@"'';
in {
  imports = [
    modules/graphical.nix
    modules/development.nix
  ];

  boot.loader.systemd-boot.editor = false;
  hardware.bluetooth.enable = true;
  location.provider = "geoclue2";
  networking.nftables.enable = true;
  networking.networkmanager.enable = true;
  networking.modemmanager.enable = false;

  # Select internationalisation properties
  i18n = {
    defaultLocale = "sv_SE.UTF-8";
    extraLocaleSettings = { LC_MESSAGES = "en_US.UTF-8"; };
  };
  console.useXkbConfig = true;
  services.xserver.xkb = {
    layout = "se-custom,se";
    extraLayouts.se-custom = {
      description = "Swedish with customizations";
      languages = [ "swe" "eng" ];
      symbolsFile = xkb/symbols/se-custom;
    };
    options = "caps:escape,shift:both_capslock,grp:ctrls_toggle";
  };
  time.timeZone = "Europe/Stockholm";

  # Use block cursor in the Linux VT. The VGA standard offers no way
  # to alter the cursor blink rate, so make it invisible and emulate
  # in software.
  boot.kernelParams = [ "vt.cur_default=0x000071" ];
  # Disable blinking entirely in the the Linux Framebuffer Console,
  # since, e.g., text editors override the default set above.
  systemd.tmpfiles.rules = [ "w /sys/class/graphics/fbcon/cursor_blink - - - - 0" ];

  nixpkgs.config.allowUnfree = true;
  environment.defaultPackages = [];
  programs.nano.enable = false;
  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    emacs-nox
    tmux curl git ripgrep
    zip unzip
    rsync strace

    run0-sudo-shim
    (callPackage packages/spotify-mix-playlists {})
  ];
  environment.variables.EDITOR = "${pkgs.ed}/bin/ed";
  environment.localBinInPath = true; # Prepend ~/.local/bin to $PATH

  security.polkit.enable = true;
  security.sudo.enable = false; # Disable sudo in favor of run0

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
  services.openssh = {
    enable = true;
    authorizedKeysInHomedir = true;
    settings.PasswordAuthentication = false;
  };

  users.mutableUsers = false;
  # Define a user account
  users.users.axel = {
    isNormalUser = true;
    description = "Axel Forsman";
    extraGroups = [ "wheel" "networkmanager" "wireshark" ];
    hashedPassword = "$y$j9T$Cim4CKzHtQoolfLgJex6a0$IhcEdatPB9nVf8PjkD/duuQdvHB08aPsfcRXtzcsqa5";
  };

  nix.settings = {
    use-xdg-base-directories = true;
    experimental-features = [ "nix-command" "flakes" ];

    substituters = [
      "https://nix-community.cachix.org"
      "https://cache.iog.io" # Binary cache for Haskell.nix
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
    ];
  };
}
