{ config, pkgs, lib, inputs, ... }:

let
  cfg = config.graphical;
  quickshell = inputs.quickshell.packages.x86_64-linux.quickshell.override {
    withX11 = false;
    withHyprland = false;
    withI3 = false;
  };

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

  defaultSession = "niri";
  sessionPackage = lib.findFirst
    (pkg: builtins.elem defaultSession pkg.providedSessions)
    (throw "session not found") config.services.displayManager.sessionPackages;
  startde = pkgs.runCommandLocal "startde" {} ''
    parse_desktop_file() {
      while IFS= read -r line; do
        case $line in
          \#* | '[Desktop Entry]') continue ;;
          \[*\]) break ;; # Desktop Entry group header must come first
        esac
        [[ $line =~ ^([A-Za-z0-9-]+)[[:space:]]*=[[:space:]]*(.*)$ ]] || continue
        value=''${BASH_REMATCH[2]//'\\'/\\}
        case ''${BASH_REMATCH[1]} in
          Name) name=$value ;;
          Exec) [[ $value =~ ^[\`$]|[^\\][\`$] ]] && { >&2 echo invalid Exec; return 1; }
            declare -agr exec=($value) ;; # TODO Prepend startx if Type=XSession
        esac
      done <"$1"
    }
    for f in ${sessionPackage}/share/{wayland-sessions,xsessions}/${defaultSession}.desktop; do
      [[ -e $f ]] && { parse_desktop_file "$f" || exit; break; }
    done
    [[ $name ]] || { >&2 echo 'desktop entry not found'; exit 1; }
    cat <<EOF >$out
    #!/bin/sh
    echo 'Starting $name...'
    unset XDG_VTNR
    exec ''${exec[@]@Q}
    EOF
    chmod +x $out
  '';

  quickshellDesktopItem = pkgs.makeDesktopItem {
    name = "org.quickshell";
    destination = "/etc/xdg/autostart";
    desktopName = "Quickshell";
    noDisplay = true;
    icon = "org.quickshell";
    exec = lib.getExe quickshell;
  };
  backlightctl = pkgs.callPackage ../packages/backlightctl {};
  pw-target = pkgs.callPackage ../packages/pw-target {};
in {
  options.graphical.enable = lib.mkEnableOption "a graphical environment";

  config = lib.mkIf cfg.enable {
    # Allow video group to control screen brightness
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video $sys$devpath/brightness", RUN+="${pkgs.coreutils}/bin/chmod g+w $sys$devpath/brightness"
    '';

    environment.loginShellInit = ''
      ! [ "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ] && exec ${startde}
    '';
    services.xserver = {
      enable = true;
      autoRepeatDelay = 300;
      autoRepeatInterval = 300;
      excludePackages = [ pkgs.xterm ];
      displayManager.lightdm.enable = false;
    };
    services.libinput.touchpad = {
      naturalScrolling = true;
      tappingDragLock = false; # Quit dragging immediately after release
    };

    services.speechd.enable = false;
    security.rtkit.enable = true; # For PipeWire
    services.upower.enable = config.powerManagement.enable;
    services.openssh.startWhenNeeded = true;
    services.spotify-inhibit-sleepd.enable = true;
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
        };
      };
    };
    environment.systemPackages = with pkgs; [
      wl-clipboard # System clipboard support in terminal Emacs
      libsecret # CLI (secret-tool) for the freedesktop.org Secret Service API
      editorDesktopItem
      backlightctl pw-target

      phinger-cursors
      quickshell quickshellDesktopItem

      foot nautilus spotify inkscape
      melonds
    ];
    environment.variables = {
      NIXOS_OZONE_WL = "1"; # Wayland Ozone platform for Electron
      MOZ_USE_XINPUT2 = "1";
    };

    xdg.mime.defaultApplications = {
      # All text/* MIME types are subclasses of text/plain
      "text/plain" = "editor.desktop";
      "application/pdf" = "firefox.desktop";
    };
    xdg.icons.fallbackCursorThemes = [ "phinger-cursors-dark" ];
    xdg.terminal-exec = { enable = true; settings.default = [ "foot.desktop" ]; };

    fonts = {
      packages = with pkgs; [ noto-fonts iosevka-custom ];
      enableDefaultPackages = false;
      fontconfig.defaultFonts = {
        sansSerif = [ "Noto Sans" ];
        serif = [ "Noto Serif" ];
        monospace = [ "Iosevka" "Noto Sans Mono" ];
      };
      fontconfig.subpixel.rgba = "rgb";
    };

    programs.niri.enable = true;
    environment.etc."niri/config.kdl".source = niri/config.kdl;
    system.checks = [ (pkgs.runCommandLocal "niri-validate" {} ''
      ${lib.getExe pkgs.niri} validate --config ${niri/config.kdl} >$out
    '') ];
    # Delay until XDG_CURRENT_DESKTOP is imported into systemd user environment
    systemd.user.services.xdg-desktop-portal.after = [ "niri.service" ];

    services.logind.settings.Login = { IdleAction = "sleep"; IdleActionSec = 300; };
    systemd.user.services.swayidle = {
      description = "Idle manager";
      documentation = [ "man:swayidle(1)" ];
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      requisite = [ "graphical-session.target" ];
      wantedBy = [ "niri.service" ];
      serviceConfig = {
        ExecStart = ''
          ${lib.getExe pkgs.swayidle} -w idlehint 300 \
            lock "${lib.getExe quickshell} ipc call lockscreen lock" \
            unlock "${lib.getExe quickshell} ipc call lockscreen unlock" \
            before-sleep "loginctl lock-session" \
            timeout 300 "${lib.getExe pkgs.niri} msg action power-off-monitors"
        '';
        Slice = "session.slice";
        Restart = "on-failure";
      };
    };
  };
}
