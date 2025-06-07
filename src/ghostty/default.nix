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
    xdg.configFile."ghostty/shaders/ghostty".source = ghostty-shaders;
    xdg.configFile."ghostty/shaders/self".source = ./shaders;

    programs.ghostty.enable = true;
    programs.ghostty.installVimSyntax = true;
    programs.ghostty.settings = {
      config-file = "?dev";
      font-family = "${config.stylix.fonts.monospace.name}";
      font-family-bold = "${config.stylix.fonts.monospace.name} Bold";
      font-family-italic = "${config.stylix.fonts.monospace.name} Italic";
      font-family-bold-italic = "${config.stylix.fonts.monospace.name} Bold Italic";
      # custom-shader = "${./bloom.glsl}";
      cursor-style = "block";
      cursor-style-blink = false;
      command = "${shell.package}/bin/${shell.bin}";
      background-opacity = 0.7;
      background-blur = true;
    };
  };
}
