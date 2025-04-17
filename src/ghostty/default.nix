{ lib
, config
, ghostty-shaders
, ...
}:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;

  shell = config.dot.shell;
in
{
  branch.homeManagerModule.homeManagerModule = lib.mkIf (hasKeyboard && hasMonitor) {
    xdg.configFile."ghostty/shaders/ghostty".target = "${ghostty-shaders}";

    programs.ghostty.enable = true;
    programs.ghostty.installVimSyntax = true;
    programs.ghostty.settings = {
      config-file = "?dev";
      cursor-style = "block";
      cursor-style-blink = false;
      command = "${shell.package}/bin/${shell.bin}";
      background-opacity = 0.7;
      background-blur = true;
    };
  };
}
