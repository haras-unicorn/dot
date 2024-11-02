{ config, lib, ... }:

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

  graphics =
    if
      (builtins.hasAttr "graphics_card" config.facter.report.hardware) &&
      ((builtins.length config.facter.report.hardware.graphics_card) > 0)
    then
      config.facter.report.hardware.graphics_card.driver
    else
      null;

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

      network = lib.mkOption {
        type = lib.types.bool;
        default = network;
      };

      bluetooth = lib.mkOption {
        type = lib.types.bool;
        default = bluetooth;
      };

      sound = lib.mkOption {
        type = lib.types.bool;
        default = sound;
      };

      monitor = lib.mkOption {
        type = lib.types.bool;
        default = monitor;
      };

      graphics = lib.mkOption {
        type = lib.types.nullOr lib.types.enum [ "nvidia" "amd" ];
        default = graphics;
      };

      keyboard = lib.mkOption {
        type = lib.types.bool;
        default = keyboard;
      };

      mouse = lib.mkOption {
        type = lib.types.bool;
        default = mouse;
      };
    };
  };
}
