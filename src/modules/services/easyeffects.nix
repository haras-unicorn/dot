{
  self.homeModules.easyeffects.value =
    {
      lib,
      config,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      presets = osConfig.dot.easyeffects;

      easyeffects = config.services.easyeffects.package;

      # EasyEffects looks autoload files up by this name and replaces "/"
      autoloadName = preset: builtins.replaceStrings [ "/" ] [ "_" ] "${preset.device}:${preset.route}";

      presetFiles =
        kind:
        lib.concatMapAttrs (
          name: preset: {
            "easyeffects/${kind}/${name}.json".source = preset.preset;
            "easyeffects/autoload/${kind}/${autoloadName preset}.json".text = builtins.toJSON {
              device = preset.device;
              device-description = preset.description;
              device-profile = preset.route;
              preset-name = name;
            };
          }
        );
    in
    lib.mkIf hardware.sound {
      home.packages = [ easyeffects ];

      xdg.dataFile = lib.mergeAttrsList [
        (presetFiles "output" presets.output)
        (presetFiles "input" presets.input)
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
