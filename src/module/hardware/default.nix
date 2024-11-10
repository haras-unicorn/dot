{ self, pkgs, config, lib, ... }:

# TODO: temp and monitor id from facter

let
  memoryInBytes = (builtins.head (builtins.head config.facter.report.hardware.memory).resources).range;

  network =
    (builtins.hasAttr "network_controller" config.facter.report.hardware) &&
    ((builtins.length config.facter.report.hardware.network_controller) > 0);

  networkInterface =
    if network then
      let
        network = builtins.head config.facter.report.hardware.network_controller;
      in
      network.unix_device_name
    else null;

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

  nvidia = (self.lib.nvidia pkgs).frozen;

  matchNvidiaList = list:
    if graphics then
      let
        graphics = builtins.head config.facter.report.hardware.graphics_card;
      in
      graphics.driver == "nvidia"
      && (builtins.any
        (pciId: (builtins.match "^pci:.+d.*${pciId}sv.+$" graphics.module_alias) != null)
        nvidia.${list})
    else false;

  graphicsVersion =
    if (matchNvidiaList "legacy340") then "legacy_340"
    else if (matchNvidiaList "legacy390") then "legacy_390"
    else if (matchNvidiaList "legacy470") then "legacy_470"
    else if (matchNvidiaList "open") then "latest"
    else "production";

  graphicsOpen = matchNvidiaList "open";

  graphicsWayland = !(matchNvidiaList "legacy");

  keyboard = bluetooth ||
    ((builtins.hasAttr "keyboard" config.facter.report.hardware) &&
      ((builtins.length config.facter.report.hardware.keyboard) > 0));

  mouse = bluetooth ||
    ((builtins.hasAttr "mouse" config.facter.report.hardware) &&
      ((builtins.length config.facter.report.hardware.mouse) > 0));
in
{
  options = {
    hardware = {
      rpi."4".enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };

      memory = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = memoryInBytes;
      };

      temp = lib.mkOption {
        type = lib.types.str;
        default = "/sys/class/hwmon/hwmon0/temp1_input";
        description = ''
          cat /sys/class/hwmon/hwmon*/name
          k10temp or coretemp then temp1_input
        '';
      };

      network.enable = lib.mkOption {
        type = lib.types.bool;
        default = network;
      };

      network.interface = lib.mkOption {
        type = lib.types.str;
        default = networkInterface;
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

      monitor.main = lib.mkOption {
        type = lib.types.str;
        default = "DP-1";
        description = ''
          xrandr --query
          hyprctl monitors
          swaymsg -t get_outputs
        '';
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

      check = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
  };

  config = {
    shared = {
      dot = {
        hardware.check =
          builtins.trace
            (lib.assertMsg
              (config.facter.report.hardware.version == "1")
              "Only facter report version 1 supported")
            false;
      };
    };
  };
}
