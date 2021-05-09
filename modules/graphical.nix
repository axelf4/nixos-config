{config, pkgs, lib, ...}:
let
  cfg = config.graphical;
in
{
  options = {
    graphical = {
      enable = lib.mkOption {
        default = false;
        type = lib.types.bool;
        description = ''
          Whether to enable a graphical environment.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable the X11 windowing system
    services.xserver = {
      enable = true;
      autoRepeatDelay = 200;
      autoRepeatInterval = 100;
      
      # Enable touchpad support.
      libinput = {
        enable = true;
        naturalScrolling = true;
        tappingDragLock = false; # Quit dragging immediately after release
        # Hack to make options only apply to touchpad (see NixOS/nixpkgs#75007)
        additionalOptions = ''MatchIsTouchpad "on"'';
      };

      # Enable the KDE Desktop Environment
      desktopManager.plasma5.enable = true;
    };

    security.pam.services.lightdm.enableKwallet = true;

    environment.systemPackages = with pkgs; [
      xclip # System clipboard support in terminal Emacs

      firefox alacritty spotify
      gimp inkscape

      jetbrains.idea-community
    ];
  };
}
