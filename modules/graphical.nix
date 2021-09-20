{config, pkgs, lib, ...}:
let
  cfg = config.graphical;

  editorDesktopItem = pkgs.makeDesktopItem {
    name = "editor";
    desktopName = "Editor";
    comment = "Edit text";
    # Lookup $VISUAL in the user's preferred shell
    exec = ''/bin/sh -c "exec \\\\"\\\\\$SHELL\\\\" -lc 'exec \\\\\$VISUAL \\\\"\\\\\$@\\\\"' \\\\"\\\\\$SHELL\\\\" \\\\"\\\\\$@\\\\"" /bin/sh %F'';
    terminal = true;
    mimeType = "text/plain;";
    icon = "emacs";
    extraDesktopEntries."NoDisplay" = "true"; # Added as proper field in 21.09
    fileValidation = false; # desktop-file-utils validated \\" wrongly until v0.25
  };
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
      editorDesktopItem
      (callPackage ../packages/edit-selection {})

      firefox alacritty spotify
      gimp inkscape

      jetbrains.idea-community
    ];
    environment.variables = {
      TERMINAL = "alacritty";
      MOZ_USE_XINPUT2 = "1";
      XDG_CONFIG_DIRS = [ "/etc/xdg" ];
    };
    environment.etc."xdg/mimeapps.list".text = ''
      [Default Applications]
      # All text/* MIME types are subclasses of text/plain
      text/plain=editor.desktop;
    '';

    fonts = {
      fonts = [ pkgs.iosevka-custom ];
      fontconfig.defaultFonts.monospace = [ "Iosevka" ];
    };
  };
}
