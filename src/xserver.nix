{ pkgs, lib, config, ... }:

let
  user = config.dot.user;

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
  branch.nixosModule.nixosModule = lib.mkIf (hasMonitor && !hasWayland) {
    services.xserver.enable = true;

    programs.ydotool.enable = true;
    users.users.${user}.extraGroups = [
      config.programs.ydotool.group
    ];
  };

  branch.homeManagerModule.homeManagerModule = lib.mkIf (hasMonitor && !hasWayland) {
    dot.desktopEnvironment.sessionVariables = {
      QT_QPA_PLATFORM = "xcb";
    };

    dot.desktopEnvironment.keybinds = lib.mkIf hasKeyboard [
      {
        mods = [ "ctrl" "alt" ];
        key = "v";
        command = "${pastedo}/bin/pastedo";
      }
    ];

    home.packages = [
      pkgs.libsForQt5.qt5ct

      pkgs.xclip
      copy
      paste
      pkgs.ydotool

      pkgs.libnotify
    ];
  };
}
