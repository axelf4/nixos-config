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
    unset XDG_VTNR
    exec ''${exec[@]@Q}
    EOF
      chmod +x $out
      exit
    done
    >&2 echo 'Desktop entry not found'; exit 1
  '';

  quickshellDesktopItem = pkgs.makeDesktopItem {
    name = "org.quickshell";
    destination = "/etc/xdg/autostart";
    desktopName = "Quickshell";
    noDisplay = true;
    icon = "org.quickshell";
    exec = lib.getExe pkgs.quickshell;
  };
  polkit-kde-agent-1' = pkgs.runCommandLocal "polkit-kde-agent-1-wrapped" {} ''
    install -Dm644 {${pkgs.kdePackages.polkit-kde-agent-1}/share,$out/lib}/systemd/user/plasma-polkit-agent.service
  '';
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
      melonDS
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
    services.displayManager.defaultSession = "niri";
    environment.etc."niri/config.kdl".source = niri/config.kdl;
    system.checks = [ (pkgs.runCommandLocal "niri-validate" {} ''
      ${lib.getExe pkgs.niri} validate --config ${niri/config.kdl} >$out
    '') ];
    # Delay until XDG_CURRENT_DESKTOP is imported into systemd user environment
    systemd.user.services.xdg-desktop-portal.after = [ "niri.service" ];

    systemd.packages = [ polkit-kde-agent-1' ];
    systemd.user.services.plasma-polkit-agent =
      { after = [ "graphical-session.target" ]; wantedBy = [ "niri.service" ]; };

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
            lock "${lib.getExe pkgs.quickshell} ipc call lockscreen lock" \
            unlock "${lib.getExe pkgs.quickshell} ipc call lockscreen unlock" \
            before-sleep "loginctl lock-session" \
            timeout 300 "${lib.getExe pkgs.niri} msg action power-off-monitors"
        '';
        Slice = "session.slice";
        Restart = "on-failure";
      };
    };
  };
}
