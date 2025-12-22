{
  pkgs,
  lib,
  config,
  ...
}:

let
  hasSound = config.dot.hardware.sound.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;

  # FIXME: https://github.com/wwmm/easyeffects/issues/4402
  toggleEasyeffectsBypass = pkgs.writeShellApplication {
    name = "toggle-easyeffects-bypass";
    runtimeInputs = [
      pkgs.easyeffects
      pkgs.coreutils
    ];
    text = ''
      if [ "$(easyeffects -b 3)" = "1" ]; then
        easyeffects -b 2
      else
        easyeffects -b 1
      fi
    '';
  };
in
{
  homeManagerModule = lib.mkIf (hasSound && hasMonitor) {
    dot.desktopEnvironment.keybinds = lib.mkIf hasKeyboard [
      {
        mods = [
          "shift"
          "super"
        ];
        key = "v";
        command = ''${toggleEasyeffectsBypass}/toggle-easyeffects-bypass'';
      }
    ];

    dot.desktopEnvironment.windowrules = [
      {
        rule = "float";
        selector = "class";
        arg = "com.github.wwmm.easyeffects";
      }
    ];

    home.packages = [
      pkgs.easyeffects
    ];

    services.easyeffects.enable = true;

    xdg.dataFile."easyeffects/output/krk.json".source = ./krk.json;
  };
}
