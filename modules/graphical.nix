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
    find -L ${config.services.displayManager.sessionData.desktops}/share/{xsessions,wayland-sessions} \
      -type f -name '*.desktop' -printf '%H\0%P\0' |
      while IFS= read -rd ''' dir && IFS= read -rd ''' file; do
      desktopFileId=''${file//'/'/-}
      [[ $desktopFileId == ${config.services.displayManager.defaultSession}.desktop ]] || continue
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
      cat <<EOF >$out
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
  options.graphical.enable = lib.mkEnableOption "a graphical environment";

  config = lib.mkIf cfg.enable {
    security.rtkit.enable = true; # For PipeWire

    services.xserver = {
      enable = true;
      autoRepeatDelay = 300;
      autoRepeatInterval = 300;
    };
    services.libinput.touchpad = {
      naturalScrolling = true;
      tappingDragLock = false; # Quit dragging immediately after release
    };
    # Enable the KDE Desktop Environment
    services.desktopManager.plasma6 = {
      enable = true;
      enableQt5Integration = false;
    };
    environment.plasma6.excludePackages = with pkgs.kdePackages;
      [ konsole elisa gwenview kate khelpcenter ];

    services.xserver.displayManager.lightdm.enable = false;
    environment.loginShellInit = ''
      ! [ "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ] && exec ${startde}
    '';

    services.spotify-inhibit-sleepd.enable = true;
    programs.kdeconnect.enable = true;
    programs.firefox = {
      enable = true;
      policies = {
        DisableFirefoxStudies = true;
        DisablePocket = true;
        Preferences = {
          "widget.use-xdg-desktop-portal.file-picker".Value = 1;
          "browser.compactmode.show".Value = true;
          "browser.quitShortcut.disabled".Value = true; # Disable CTRL-Q
          "browser.urlbar.suggest.calculator".Value = true;
          # Allow adding search engines
          "browser.urlbar.update2.engineAliasRefresh".Value = true;
          "extensions.quarantinedDomains.enabled".Value = false;
        };
      };
    };
    environment.systemPackages = with pkgs; [
      wl-clipboard # System clipboard support in terminal Emacs
      editorDesktopItem
      # (callPackage ../packages/edit-selection {})

      alacritty spotify inkscape
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
