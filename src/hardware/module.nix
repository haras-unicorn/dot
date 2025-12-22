{
  self,
  config,
  lib,
  ...
}:

# TODO: temp and monitor id from facter

let
  memoryInBytes =
    (builtins.head (builtins.head config.facter.report.hardware.memory).resources).range;

  threads =
    let
      cpu = builtins.head config.facter.report.hardware.cpu;
    in
    if builtins.hasAttr "units" cpu then cpu.units else 2;

  network =
    (builtins.hasAttr "network_controller" config.facter.report.hardware)
    && ((builtins.length config.facter.report.hardware.network_controller) > 0);

  networkInterface =
    if network then
      let
        network = builtins.head (
          lib.sortOn (interface: if lib.hasPrefix "e" interface.unix_device_name then 0 else 1) (
            builtins.filter (
              interface: interface.unix_device_name != "lo"
            ) config.facter.report.hardware.network_interface
          )
        );
      in
      network.unix_device_name
    else
      null;

  diskInBytes =
    let
      resource = (
        builtins.head (
          builtins.filter (resource: resource.type == "size" && resource.unit == "sectors")
            (builtins.head (
              builtins.filter (disk: builtins.hasAttr "vendor" disk) config.facter.report.hardware.disk
            )).resources
        )
      );
    in
    resource.value_1 * resource.value_2;

  bluetooth =
    (builtins.hasAttr "bluetooth" config.facter.report.hardware)
    && ((builtins.length config.facter.report.hardware.bluetooth) > 0);

  sound =
    (builtins.hasAttr "sound" config.facter.report.hardware)
    && ((builtins.length config.facter.report.hardware.sound) > 0);

  monitor =
    (builtins.hasAttr "monitor" config.facter.report.hardware)
    && ((builtins.length config.facter.report.hardware.monitor) > 0);

  monitorWidth =
    if monitor then (builtins.head config.facter.report.hardware.monitor).detail.width else null;

  monitorHeight =
    if monitor then (builtins.head config.facter.report.hardware.monitor).detail.height else null;

  monitorDpi =
    if monitor then
      let
        monitor = builtins.head config.facter.report.hardware.monitor;
      in
      (monitor.detail.width / (monitor.detail.width_millimetres / 25.4))
    else
      null;

  graphics =
    (builtins.hasAttr "graphics_card" config.facter.report.hardware)
    && ((builtins.length config.facter.report.hardware.graphics_card) > 0);

  graphicsCards =
    let
      raw = config.facter.report.hardware.graphics_card or [ ];
      sumMemory =
        card:
        builtins.foldl' (
          sum: resource: sum + (if (resource.type or "") == "mem" then (resource.range or 0) else 0)
        ) 0 (card.resources or [ ]);
    in
    builtins.sort (lhs: rhs: sumMemory lhs > sumMemory rhs) raw;

  graphicsCard =
    if (!graphics) || (builtins.length graphicsCards < 1) then
      null
    else
      builtins.elemAt graphicsCards 0;

  integratedGraphicsCard =
    if (!graphics) || (builtins.length graphicsCards < 2) then
      null
    else
      builtins.elemAt graphicsCards 1;

  # NOTE: kinda brittle but works
  # "0000:0c:00.0" -> "PCI:12:0:0"
  sysfsBusIdToBusId =
    sysFsBusId:
    let
      matched = builtins.match "^[0-9a-fA-F]{4}:([0-9a-fA-F]{2}):([0-9a-fA-F]{2}).([0-7])$" sysFsBusId;
      bus = self.lib.hex.hexToDec (builtins.elemAt matched 0);
      dev = self.lib.hex.hexToDec (builtins.elemAt matched 1);
      fn = self.lib.hex.hexToDec (builtins.elemAt matched 2);
    in
    "PCI:${toString bus}:${toString dev}:${toString fn}";

  graphicsDriver = if graphicsCard == null then null else graphicsCard.driver;

  graphicsBusId = if graphicsCard == null then null else sysfsBusIdToBusId graphicsCard.sysfs_bus_id;

  integratedGraphicsDriver =
    if integratedGraphicsCard == null then null else integratedGraphicsCard.driver;

  integratedGraphicsBusId =
    if integratedGraphicsCard == null then
      null
    else
      sysfsBusIdToBusId integratedGraphicsCard.sysfs_bus_id;

  nvidia = self.lib.nvidia.frozen;

  matchNvidiaList =
    list:
    if graphics then
      let
        graphics = builtins.head config.facter.report.hardware.graphics_card;
      in
      graphics.driver == "nvidia"
      && (builtins.any (
        pciId: (builtins.match "^pci:.+d.*${pciId}sv.+$" graphics.module_alias) != null
      ) nvidia.${list})
    else
      false;

  graphicsVersion =
    if (matchNvidiaList "legacy340") then
      "legacy_340"
    else if (matchNvidiaList "legacy390") then
      "legacy_390"
    else if (matchNvidiaList "legacy470") then
      "legacy_470"
    else if (matchNvidiaList "open") then
      "latest"
    else
      "production";

  graphicsOpen = matchNvidiaList "open";

  graphicsWayland = !(matchNvidiaList "legacy");

  keyboard =
    bluetooth
    || (
      (builtins.hasAttr "keyboard" config.facter.report.hardware)
      && ((builtins.length config.facter.report.hardware.keyboard) > 0)
    );

  mouse =
    bluetooth
    || (
      (builtins.hasAttr "mouse" config.facter.report.hardware)
      && ((builtins.length config.facter.report.hardware.mouse) > 0)
    );

  options.dot.hardware = {
    rpi."4".enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    battery.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    memory = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = memoryInBytes;
    };

    disk = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = diskInBytes;
    };

    threads = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = threads;
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
      type = lib.types.nullOr (
        lib.types.enum [
          "nvidia"
          "amdgpu"
          "intel"
        ]
      );
      default = graphicsDriver;
    };

    graphics.busId = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = graphicsBusId;
    };

    graphics.integrated.driver = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "nvidia"
          "amdgpu"
          "intel"
        ]
      );
      default = integratedGraphicsDriver;
    };

    graphics.integrated.busId = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = integratedGraphicsBusId;
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

  configHere = {
    dot.hardware.check = builtins.trace (lib.assertMsg (
      config.facter.report.version == "1"
    ) "Only facter report version 1 supported") false;
  };
in
{
  nixosModule = {
    inherit options;
    config = lib.mkMerge [
      configHere
      {
        hardware.enableAllFirmware = true;
      }
    ];
  };

  homeManagerModule = {
    inherit options;
    config = configHere;
  };
}
