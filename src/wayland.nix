{ pkgs, lib, config, ... }:

let
  cfg = config.dot.desktopEnvironment;

  copy = pkgs.writeShellApplication {
    name = "copy";
    runtimeInputs = [ pkgs.wl-clipboard pkgs.xclip ];
    text = ''
      to_copy="$(cat)"
      "$to_copy" | wl-copy
      "$to_copy" | xclip -sel clipboard
    '';
  };

  paste = pkgs.writeShellApplication {
    name = "paste";
    runtimeInputs = [ pkgs.wl-clipboard ];
    text = ''
      wl-paste
    '';
  };

  pastedo = pkgs.writeShellApplication {
    name = "pastex";
    runtimeInputs = [ pkgs.xclip pkgs.dotool ];
    text = ''
      echo "type $(wl-paste)" | dotool 
    '';
  };

  wclipwatch = pkgs.writeShellApplication {
    name = "wclipwatch";
    runtimeInputs = [ pkgs.wl-clipboard pkgs.xclip ];
    text = ''
      wl-paste --type text --watch xclip -sel clipboard
    '';
  };

  xclipwatch = pkgs.writeShellApplication {
    name = "xclipwatch";
    runtimeInputs = [ pkgs.clipnotify pkgs.wl-clipboard pkgs.xclip ];
    text = ''
      while clipnotify; do
        if [ "$(xclip -o -sel clipboard)" != "$(wl-paste)" ]; then
          xclip -o -sel clipboard | wl-copy
        fi
      done
    '';
  };

  hasMonitor = config.dot.hardware.monitor.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  branch.nixosModule.nixosModule = lib.mkIf (hasMonitor && hasWayland) {
    services.greetd.enable = true;
    services.greetd.settings = {
      default_session = {
        command = cfg.login;
      };
    };
  };

  branch.homeManagerModule.homeManagerModule = lib.mkIf (hasMonitor && hasWayland) {
    dot.desktopEnvironment.sessionVariables = {
      QT_QPA_PLATFORM = "wayland;xcb";
      NIXOS_OZONE_WL = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
      XDG_SESSION_TYPE = "wayland";
      MOZ_ENABLE_WAYLAND = "1";
      NIXOS_XDG_OPEN_USE_PORTAL = "1";
      GDK_BACKEND = "wayland,x11";
      CLUTTER_BACKEND = "wayland";
      SDL_VIDEODRIVER = "wayland,x11";
      _JAVA_AWT_WM_NONREPARENTING = "1";
    };

    dot.desktopEnvironment.sessionStartup = [
      "${wclipwatch}/bin/wclipwatch"
      "${xclipwatch}/bin/xclipwatch"
    ];

    dot.desktopEnvironment.keybinds = lib.mkIf hasKeyboard [
      {
        mods = [ "ctrl" "alt" ];
        key = "v";
        command = "${pastedo}/bin/pastedo";
      }
    ];

    home.packages = [
      pkgs.egl-wayland
      pkgs.xwaylandvideobridge

      pkgs.libsForQt5.qt5ct
      pkgs.qt6.qtwayland
      pkgs.libsForQt5.qt5.qtwayland

      pkgs.wev

      pkgs.wl-clipboard
      pkgs.xclip
      copy
      paste

      pkgs.libnotify

      pkgs.libdecor
    ];
  };
}
