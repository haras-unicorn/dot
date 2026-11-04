{
  self.nixosModules.easyeffects.value =
    { lib, ... }:
    let
      presetModule =
        { config, ... }:
        {
          options = {
            preset = lib.mkOption {
              type = lib.types.path;
              description = ''
                EasyEffects preset JSON file, installed under the name of this
                entry.
              '';
            };

            device = lib.mkOption {
              type = lib.types.str;
              description = ''
                PipeWire node name of the device (`Name` in `pactl list sinks`
                or `pactl list sources`). The preset is loaded when this
                device becomes the selected one.
              '';
            };

            route = lib.mkOption {
              type = lib.types.str;
              description = ''
                Description of the active port of the device (the text after
                the port name in the `Ports` of `pactl list sinks`, for
                example `Headphones`).
              '';
            };

            description = lib.mkOption {
              type = lib.types.str;
              default = config.device;
              description = ''
                Human-readable device name EasyEffects shows in its autoload
                list.
              '';
            };
          };
        };

      presetsOption =
        description:
        lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule presetModule);
          default = { };
          inherit description;
        };
    in
    {
      options.dot.easyeffects = {
        output = presetsOption ''
          EasyEffects output presets by name. Each one is loaded when its
          device becomes the default output device.
        '';

        input = presetsOption ''
          EasyEffects input presets by name. Each one is loaded when its
          device is the selected input device. EasyEffects does not move the
          selection to a new default input device, so this only switches
          presets for a device that is already selected.
        '';
      };
    };
}
