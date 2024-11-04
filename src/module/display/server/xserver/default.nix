{ pkgs, ... }:

let
  copy = pkgs.writeShellApplication {
    name = "copy";
    runtimeInputs = [ pkgs.xclip ];
    text = ''
      cat | xclip -sel clip "$@"
    '';
  };

  paste = pkgs.writeShellApplication {
    name = "copy";
    runtimeInputs = [ pkgs.xclip ];
    text = ''
      xclip -o -sel clip "$@"
    '';
  };
in
{
  system = {
    environment.sessionVariables = {
      QT_QPA_PLATFORM = "xcb";
      # NIXOS_OZONE_WL = "1";
      # WLR_NO_HARDWARE_CURSORS = "1";
      # XDG_SESSION_TYPE = "wayland";
      # MOZ_ENABLE_WAYLAND = "1";
      # NIXOS_XDG_OPEN_USE_PORTAL = "1";
      # GDK_BACKEND = "wayland";
      # CLUTTER_BACKEND = "wayland";
      # _JAVA_AWT_WM_NONREPARENTING = "1";
    };

    environment.systemPackages = with pkgs; [
      libsForQt5.qt5ct

      xclip
      copy
      paste

      libnotify
    ];

    services.xserver.enable = true;
    services.xserver.xkb.layout = "us";
    services.libinput.enable = true;

    console.useXkbConfig = true;
  };
}
