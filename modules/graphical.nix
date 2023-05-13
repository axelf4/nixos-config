{ config, pkgs, lib, ... }:
let
  cfg = config.graphical;

  editorDesktopItem = pkgs.makeDesktopItem {
    name = "editor";
    desktopName = "Text Editor";
    noDisplay = true;
    comment = "Edit text";
    icon = "accessories-text-editor";
    # Lookup $VISUAL in the user's preferred shell
    exec = ''/bin/sh -c "exec \\"\\$SHELL\\" -lc 'exec \\$VISUAL \\"\\$@\\"' \\"\\$SHELL\\" \\"\\$@\\"" /bin/sh %F'';
    terminal = true;
    mimeTypes = [ "text/plain" ];
  };
in {
  options.graphical = {
    enable = lib.mkEnableOption "a graphical environment";
  };

  config = lib.mkIf cfg.enable {
    security.rtkit.enable = true;
    # Enable PipeWire for audio
    services.pipewire = {
      enable = true;
      pulse.enable = true;
    };

    # Enable the X11 windowing system
    services.xserver = {
      enable = true;
      autoRepeatDelay = 300;
      autoRepeatInterval = 300;
      
      libinput.touchpad = {
        naturalScrolling = true;
        tappingDragLock = false; # Quit dragging immediately after release
      };

      # Enable the KDE Desktop Environment
      desktopManager.plasma5.enable = true;
    };
    environment.plasma5.excludePackages = with pkgs.plasma5Packages; [ konsole oxygen elisa gwenview ];

    services.spotify-inhibit-sleepd.enable = true;
    programs.kdeconnect.enable = true;
    programs.firefox = {
      enable = true;
      policies = {
        DisableFirefoxStudies = true;
        DisablePocket = true;
        Preferences = {
          "browser.compactmode.show" = { Value = true; Status = "default"; };
        };
      };
    };
    environment.systemPackages = with pkgs; [
      xclip # System clipboard support in terminal Emacs
      editorDesktopItem
      (callPackage ../packages/edit-selection {})
      ark

      alacritty spotify gimp inkscape
    ];
    environment.variables = {
      TERMINAL = "alacritty";
      MOZ_USE_XINPUT2 = "1";
    };

    xdg.mime.defaultApplications = {
      # All text/* MIME types are subclasses of text/plain
      "text/plain" = "editor.desktop";
      "application/pdf" = "firefox.desktop";
    };

    fonts = {
      fonts = [ pkgs.iosevka-custom ];
      fontconfig.defaultFonts.monospace = [ "Iosevka" ];
    };
  };
}
