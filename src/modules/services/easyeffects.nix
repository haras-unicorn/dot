{
  machines.homeModules.easyeffects =
    {
      pkgs,
      lib,
      config,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      easyeffects = config.services.easyeffects.package;

      # FIXME: https://github.com/wwmm/easyeffects/issues/4402
      toggle-bypass = pkgs.writeShellApplication {
        name = "easyeffects-toggle-bypass";
        runtimeInputs = [ easyeffects ];
        text = ''
          if [ "$(easyeffects -b 3)" = "1" ]; then
            easyeffects -b 2
          else
            easyeffects -b 1
          fi
        '';
      };
    in
    lib.mkIf hardware.sound {
      dot.desktop.keybinds = [
        {
          mods = [ "super" ];
          key = "x";
          command = lib.getExe toggle-bypass;
        }
      ];

      home.packages = [
        easyeffects
        toggle-bypass
      ];

      services.easyeffects.enable = true;
      systemd.user.services.easyeffects = lib.mkIf hardware.graphics {
        Unit.Requires = [ "tray.target" ];
        Unit.After = [
          "tray.target"
          "graphical-session.target"
        ];
      };

      dot.desktop.windowrules = [
        {
          rule = "float";
          selector = "class";
          arg = "org.kde.easyeffects";
        }
      ];
    };
}
