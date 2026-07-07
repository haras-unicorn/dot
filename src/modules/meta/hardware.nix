{
  machines.nixosModules.hardware =
    { lib, config, ... }:
    let
      detection = config.hardware.facter.detection;
      capabilities = detection.capabilities;
    in
    {
      options.dot = {
        hardware = {
          deviceType = lib.mkOption {
            type = lib.types.enum [
              "generic"
              "rpi4"
            ];
            default = "generic";
            description = "Machine device type.";
          };

          temperature = lib.mkOption {
            type = lib.types.path;
            description = "Machine CPU temperature monitor file path.";
          };

          battery = lib.mkOption {
            type = lib.types.bool;
            description = "Whether the machine has a battery.";
          };

          graphics = lib.mkOption {
            type = lib.types.bool;
            description = "Whether the machine can display graphics.";
          };

          typing = lib.mkOption {
            type = lib.types.bool;
            description = "Whether the machine can be typed into.";
          };

          pointing = lib.mkOption {
            type = lib.types.bool;
            description = "Whether the machine can be pointed into.";
          };

          sound = lib.mkOption {
            type = lib.types.bool;
            description = "Whether the machine can produce sound.";
          };

          multimedia = lib.mkOption {
            type = lib.types.bool;
            description = "Whether the machine can display multimedia.";
          };

          visual = lib.mkOption {
            type = lib.types.bool;
            description = "Whether the machine can be used to edit files via a visual editor.";
          };

          editor = lib.mkOption {
            type = lib.types.bool;
            description = "Whether the machine can be used to edit files.";
          };

          browser = lib.mkOption {
            type = lib.types.bool;
            description = "Whether the machine can be used to browse the web.";
          };

          gaming = lib.mkOption {
            type = lib.types.bool;
            description = "Whether the machine can be used to game.";
          };

          wayland = lib.mkOption {
            type = lib.types.bool;
            description = "Whether the machine supports wayland.";
          };

          threads = lib.mkOption {
            type = lib.types.ints.unsigned;
            description = "Machine CPU thread count.";
          };

          memory = lib.mkOption {
            type = lib.types.ints.unsigned;
            description = "Machine memory in bytes.";
          };

          display = lib.mkOption {
            type = lib.types.str;
            description = "Default machine monitor display port.";
          };

          dpi = lib.mkOption {
            type = lib.types.ints.unsigned;
            description = "Default machine monitor display DPI.";
          };

          width = lib.mkOption {
            type = lib.types.ints.unsigned;
            description = "Default machine monitor display width.";
          };

          height = lib.mkOption {
            type = lib.types.ints.unsigned;
            description = "Default machine monitor display height.";
          };

          network = lib.mkOption {
            type = lib.types.bool;
            description = "Whether the machine network access.";
          };

          interface = lib.mkOption {
            type = lib.types.str;
            description = "Default machine network interface.";
          };
        };
      };

      config.dot = {
        hardware = {
          battery = lib.mkDefault false;
          graphics = capabilities.graphics;
          typing = capabilities.typing;
          pointing = capabilities.pointing;
          sound = capabilities.sound;
          multimedia = capabilities.sound && capabilities.graphics;
          browser = capabilities.graphics && capabilities.typing && capabilities.pointing;
          editor = capabilities.typing || detection.network.enable;
          visual = capabilities.graphics && capabilities.typing;
          gaming =
            capabilities.sound && capabilities.graphics && capabilities.typing && capabilities.pointing;
          wayland = detection.graphics.cards.default.wayland or false;
          threads = detection.cpu.threads;
          memory = detection.memory.size;
          network = detection.network.enable;
          dpi = detection.monitor.displays.default.dpi or 0;
          interface = detection.network.interfaces.default.name or "";
          height = detection.monitor.displays.default.height or 0;
          width = detection.monitor.displays.default.width or 0;
        };
      };
    };
}
