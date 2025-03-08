{ pkgs, lib, config, ... }:

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

  pastedo = pkgs.writeShellApplication {
    name = "pastex";
    runtimeInputs = [ pkgs.xclip pkgs.dotool ];
    text = ''
      echo "type $(xclip -o -sel clip)" | dotool 
    '';
  };

  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  config = lib.mkIf (hasMonitor && !hasWayland) {
    desktopEnvironment.sessionVariables = {
      QT_QPA_PLATFORM = "xcb";
    };

    desktopEnvironment.keybinds = lib.mkIf hasKeyboard [
      {
        mods = [ "ctrl" "alt" ];
        key = "v";
        command = "${pastedo}/bin/pastedo";
      }
    ];
  };

  integrate.nixosModule.nixosModule = lib.mkIf (hasMonitor && !hasWayland) {
    services.xserver.enable = true;
  };

  integrate.homeManagerModule.homeManagerModule = lib.mkIf (hasMonitor && !hasWayland) {
    home.packages = [
      pkgs.libsForQt5.qt5ct

      pkgs.xclip
      copy
      paste

      pkgs.libnotify
    ];
  };
}
