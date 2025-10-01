{
  pkgs,
  lib,
  config,
  ...
}:

let
  copy = pkgs.writeShellApplication {
    name = "copy";
    runtimeInputs = [ pkgs.xclip ];
    text = ''
      cat | xclip -sel clip
    '';
  };

  paste = pkgs.writeShellApplication {
    name = "paste";
    runtimeInputs = [ pkgs.xclip ];
    text = ''
      xclip -o -sel clip
    '';
  };

  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  branch.nixosModule.nixosModule = lib.mkIf (hasMonitor && !hasWayland) {
    services.xserver.enable = true;
  };

  branch.homeManagerModule.homeManagerModule = lib.mkIf (hasMonitor && !hasWayland) {
    dot.desktopEnvironment.sessionVariables = {
      QT_QPA_PLATFORM = "xcb";
    };

    dot.shell.copy = copy;

    dot.shell.paste = paste;

    home.packages = [
      pkgs.libsForQt5.qt5ct
      pkgs.xclip
      pkgs.libnotify
    ];
  };
}
