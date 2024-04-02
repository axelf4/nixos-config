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

  startde = pkgs.runCommandLocal "startde" {} ''
    shopt -s lastpipe
    find -L ${config.services.xserver.displayManager.sessionData.desktops}/share/{xsessions,wayland-sessions} \
      -type f -name '*.desktop' -printf '%H\0%P\0' \
      | while IFS= read -rd ''' dir && IFS= read -rd ''' file; do
      desktopFileId=''${file//'/'/-}
      [[ $desktopFileId == ${config.services.xserver.displayManager.defaultSession}.desktop ]] || continue
      while IFS= read -r line; do # Parse desktop file
        case $line in
          \#* | '[Desktop Entry]') continue ;;
          \[*\]) break ;; # Desktop Entry group header must come first
        esac
        if [[ $line =~ ^([A-Za-z0-9-]+)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
          value=''${BASH_REMATCH[2]//'\\'/\\}
          case ''${BASH_REMATCH[1]} in
            Name) name=$value ;;
            Exec) [[ $value =~ ^[\`$]|[^\\][\`$] ]] && { >&2 echo Invalid Exec; exit 1; }
              declare -ar exec=($value) ;; # TODO Prepend startx if Type=XSession
          esac
        fi
      done <"$dir/$file"
      cat << EOF >$out
    #!/bin/sh
    echo 'Starting $name...'
    exec ''${exec[@]@Q}
    EOF
      chmod +x $out
      exit
    done
    >&2 echo 'Desktop entry not found'; exit 1
  '';
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
      displayManager.defaultSession = "plasmawayland";
    };
    environment.plasma5.excludePackages = with pkgs.plasma5Packages; [ konsole oxygen elisa gwenview ];

    services.xserver.displayManager.lightdm.enable = false;
    environment.loginShellInit = ''
      [ "$XDG_VTNR" = 1 ] && [ -z "$DISPLAY" ] && exec ${startde}
    '';

    services.spotify-inhibit-sleepd.enable = true;
    programs.kdeconnect.enable = true;
    programs.firefox = {
      enable = true;
      policies = {
        DisableFirefoxStudies = true;
        DisablePocket = true;
        Preferences = {
          "browser.compactmode.show".Value = true;
          "browser.quitShortcut.disabled".Value = true; # Disable CTRL-Q
          "browser.urlbar.suggest.calculator".Value = true;
          "extensions.quarantinedDomains.enabled".Value = false;
        };
      };
    };
    environment.systemPackages = with pkgs; [
      wl-clipboard # System clipboard support in terminal Emacs
      editorDesktopItem
      (callPackage ../packages/edit-selection {})

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
      packages = [ pkgs.iosevka-custom ];
      fontconfig.defaultFonts.monospace = [ "Iosevka" ];
      fontconfig.subpixel.rgba = "rgb";
    };
  };
}
