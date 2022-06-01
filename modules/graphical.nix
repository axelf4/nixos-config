{ config, pkgs, lib, ... }:
let
  cfg = config.graphical;

  editorDesktopItem = pkgs.makeDesktopItem {
    name = "editor";
    desktopName = "Editor";
    comment = "Edit text";
    # Lookup $VISUAL in the user's preferred shell
    exec = ''/bin/sh -c "exec \\\\"\\\\\$SHELL\\\\" -lc 'exec \\\\\$VISUAL \\\\"\\\\\$@\\\\"' \\\\"\\\\\$SHELL\\\\" \\\\"\\\\\$@\\\\"" /bin/sh %F'';
    terminal = true;
    mimeTypes = [ "text/plain" ];
    icon = "emacs";
    noDisplay = true;
  };
in {
  options.graphical = {
    enable = lib.mkEnableOption "a graphical environment";
  };

  config = lib.mkIf cfg.enable {
    # Enable the X11 windowing system
    services.xserver = {
      enable = true;
      autoRepeatDelay = 300;
      autoRepeatInterval = 300;
      
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

    services.spotify-inhibit-sleepd.enable = true;
    programs.kdeconnect.enable = true;
    environment.systemPackages = with pkgs; [
      xclip # System clipboard support in terminal Emacs
      editorDesktopItem
      (callPackage ../packages/edit-selection {})
      ark

      firefox alacritty spotify
      gimp inkscape
    ];
    environment.variables = {
      TERMINAL = "alacritty";
      MOZ_USE_XINPUT2 = "1";
    };

    xdg.mime.defaultApplications = {
      # All text/* MIME types are subclasses of text/plain
      "text/plain" = "editor.desktop";
    };

    fonts = {
      fonts = [ pkgs.iosevka-custom ];
      fontconfig.defaultFonts.monospace = [ "Iosevka" ];
    };
  };
}
