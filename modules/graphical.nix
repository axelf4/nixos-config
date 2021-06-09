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
      
      # Enable touchpad support
      libinput = {
        enable = true;
        touchpad = {
          naturalScrolling = true;
          tappingDragLock = false; # Quit dragging immediately after release
        };
      };

      # Enable the KDE Desktop Environment
      desktopManager.plasma5.enable = true;
    };

    environment.systemPackages = with pkgs; [
      xclip # System clipboard support in terminal Emacs
      (callPackage ../packages/edit-selection {})

      firefox alacritty spotify
      gimp inkscape

      jetbrains.idea-community
    ];
    environment.variables = {
      TERMINAL = "alacritty";
      MOZ_USE_XINPUT2 = "1";
    };
  };
}
