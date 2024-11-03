{ self, config, lib, ... }:

# TODO: stable wayland detection
# TODO: better graphics driver detection

let
  memoryInBytes = (builtins.head config.facter.report.hardware.memory.resources).range;

  network =
    (builtins.hasAttr "network_controller" config.facter.report.hardware) &&
    ((builtins.length config.facter.report.hardware.network_controller) > 0);

  bluetooth =
    (builtins.hasAttr "bluetooth" config.facter.report.hardware) &&
    ((builtins.length config.facter.report.hardware.bluetooth) > 0);

  sound =
    (builtins.hasAttr "sound" config.facter.report.hardware) &&
    ((builtins.length config.facter.report.hardware.sound) > 0);

  monitor =
    (builtins.hasAttr "monitor" config.facter.report.hardware) &&
    ((builtins.length config.facter.report.hardware.monitor) > 0);

  monitorWidth =
    if monitor then
      (builtins.head config.facter.report.hardware.monitor).detail.width
    else null;

  monitorHeight =
    if monitor then
      (builtins.head config.facter.report.hardware.monitor).detail.height
    else null;

  monitorDpi =
    if monitor then
      let monitor = builtins.head config.facter.report.hardware.monitor; in
      (monitor.detail.width / (monitor.detail.width_millimetres / 25.4))
    else null;

  graphics =
    (builtins.hasAttr "graphics_card" config.facter.report.hardware) &&
    ((builtins.length config.facter.report.hardware.graphics_card) > 0);

  graphicsDriver =
    if graphics then
      (builtins.head config.facter.report.hardware.graphics_card).driver
    else null;

  graphicsWayland =
    if graphics then
      let
        graphics = builtins.head config.facter.report.hardware.graphics_card;
      in
        !(graphics.driver == "nvidia"
          && (builtins.any (pciId: lib.strings.hasInfix pciId graphics.module_alias) self.lib.nvidia.legacy))
    else null;

  graphicsVersion = if graphicsWayland then "production" else "legacy_470";

  graphicsOpen = graphicsWayland;

  keyboard =
    (builtins.hasAttr "keyboard" config.facter.report.hardware) &&
    ((builtins.length config.facter.report.hardware.keyboard) > 0);

  mouse =
    (builtins.hasAttr "mouse" config.facter.report.hardware) &&
    ((builtins.length config.facter.report.hardware.mouse) > 0);
in
{
  options = {
    hardware = {
      memory = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = memoryInBytes;
      };

      network.enable = lib.mkOption {
        type = lib.types.bool;
        default = network;
      };

      bluetooth.enable = lib.mkOption {
        type = lib.types.bool;
        default = bluetooth;
      };

      sound.enable = lib.mkOption {
        type = lib.types.bool;
        default = sound;
      };

      monitor.enable = lib.mkOption {
        type = lib.types.bool;
        default = monitor;
      };

      monitor.width = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = monitorWidth;
      };

      monitor.height = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = monitorHeight;
      };

      monitor.dpi = lib.mkOption {
        type = lib.types.float;
        default = monitorDpi;
      };

      graphics.enable = lib.mkOption {
        type = lib.types.bool;
        default = graphics;
      };

      graphics.driver = lib.mkOption {
        type = lib.types.nullOr (lib.types.enum [ "nvidia" "amdgpu" ]);
        default = graphicsDriver;
      };

      graphics.wayland = lib.mkOption {
        type = lib.types.bool;
        default = graphicsWayland;
      };

      graphics.version = lib.mkOption {
        type = lib.types.str;
        default = graphicsVersion;
      };

      graphics.open = lib.mkOption {
        type = lib.types.bool;
        default = graphicsOpen;
      };

      keyboard.enable = lib.mkOption {
        type = lib.types.bool;
        default = keyboard;
      };

      mouse.enable = lib.mkOption {
        type = lib.types.bool;
        default = mouse;
      };
    };
  };
}
