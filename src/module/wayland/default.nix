{ pkgs
, lib
, config
, ...
}:

# FIXME: https://github.com/NVIDIA/open-gpu-kernel-modules/issues/467#issuecomment-1544340511
# FIXME: hyprland insists on own portal but that one doesn't allow me to screenshare at all

let
  cfg = config.dot.desktopEnvironment;

  copy = pkgs.writeShellApplication {
    name = "copy";
    runtimeInputs = [ pkgs.wl-clipboard ];
    text = ''
      cat | wl-copy "$@"
    '';
  };

  paste = pkgs.writeShellApplication {
    name = "copy";
    runtimeInputs = [ pkgs.wl-clipboard ];
    text = ''
      wl-paste "$@"
    '';
  };
in
{
  options.dot.desktopEnvironment = {
    login = lib.mkOption {
      type = lib.types.str;
      default = [ ];
      example = "tuigreet --cmd Hyprland";
      description = ''
        Login command.
      '';
    };
  };

  config = {
    system = {
      environment.sessionVariables = {
        QT_QPA_PLATFORM = "wayland;xcb";
        NIXOS_OZONE_WL = "1";
        WLR_NO_HARDWARE_CURSORS = "1";
        XDG_SESSION_TYPE = "wayland";
        MOZ_ENABLE_WAYLAND = "1";
        NIXOS_XDG_OPEN_USE_PORTAL = "1";
        GDK_BACKEND = "wayland,x11";
        CLUTTER_BACKEND = "wayland";
        # NOTE: fixes stuttering but steam games suck
        # XWAYLAND_NO_GLAMOR = "1";
        _JAVA_AWT_WM_NONREPARENTING = "1";
      };

      environment.systemPackages = with pkgs; [
        egl-wayland
        xwaylandvideobridge

        libsForQt5.qt5ct
        qt6.qtwayland
        libsForQt5.qt5.qtwayland

        wev

        wl-clipboard
        copy
        paste

        libnotify
      ];

      xdg.portal.enable = true;
      xdg.portal.config.common.default = "*";
      xdg.portal.xdgOpenUsePortal = true;
      xdg.portal.extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
        libsForQt5.xdg-desktop-portal-kde
        xdg-desktop-portal-gtk
      ];
      xdg.portal.wlr.enable = pkgs.lib.mkForce true;
      xdg.portal.wlr.settings.screencast = {
        output_name = config.dot.mainMonitor;
        max_fps = 60;
        chooser_type = "simple";
        chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
      };

      programs.dconf.enable = true;

      services.greetd.enable = true;
      services.greetd.settings = {
        default_session = {
          command = cfg.login;
        };
      };
    };
  };
}
