{ self, ... }:

# TODO: rpi 4, battery, temp and monitor id from facter

let
  common =
    { lib, config, ... }:
    let
      hasGraphics =
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
        if (!hasGraphics) || (builtins.length graphicsCards < 1) then
          null
        else
          builtins.elemAt graphicsCards 0;

      integratedGraphicsCard =
        if (!hasGraphics) || (builtins.length graphicsCards < 2) then
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

      nvidia = self.lib.nvidia.frozen;

      matchNvidiaList =
        list:
        if hasGraphics then
          let
            graphics = builtins.head config.facter.report.hardware.graphics_card;
          in
          graphics.driver == "nvidia"
          && (builtins.any (
            pciId: (builtins.match "^pci:.+d.*${pciId}sv.+$" graphics.module_alias) != null
          ) nvidia.${list})
        else
          false;
    in
    {
      dot.hardware =
        assert config.facter.report.version == 1;
        rec {

          threads =
            let
              cpu = builtins.head config.facter.report.hardware.cpu;
            in
            if builtins.hasAttr "units" cpu then cpu.units else 2;

          memory = (builtins.head (builtins.head config.facter.report.hardware.memory).resources).range;

          disk =
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

          network.enable =
            (builtins.hasAttr "network_controller" config.facter.report.hardware)
            && ((builtins.length config.facter.report.hardware.network_controller) > 0);

          network.interface =
            if network.enable then
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

          graphics.enable = hasGraphics;

          graphics.driver = if graphicsCard == null then null else graphicsCard.driver;

          graphics.version =
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

          graphics.open = matchNvidiaList "open";

          graphics.busId = if graphicsCard == null then null else sysfsBusIdToBusId graphicsCard.sysfs_bus_id;

          graphics.integrated.driver =
            if integratedGraphicsCard == null then null else integratedGraphicsCard.driver;

          graphics.integrated.busId =
            if integratedGraphicsCard == null then
              null
            else
              sysfsBusIdToBusId integratedGraphicsCard.sysfs_bus_id;

          graphics.wayland = !(matchNvidiaList "legacy");

          sound.enable =
            (builtins.hasAttr "sound" config.facter.report.hardware)
            && ((builtins.length config.facter.report.hardware.sound) > 0);

          monitor.enable =
            (builtins.hasAttr "monitor" config.facter.report.hardware)
            && ((builtins.length config.facter.report.hardware.monitor) > 0);

          monitor.width =
            if monitor.enable then (builtins.head config.facter.report.hardware.monitor).detail.width else null;

          monitor.height =
            if monitor.enable then
              (builtins.head config.facter.report.hardware.monitor).detail.height
            else
              null;

          monitor.dpi =
            if monitor.enable then
              let
                monitor = builtins.head config.facter.report.hardware.monitor;
              in
              (monitor.detail.width / (monitor.detail.width_millimetres / 25.4))
            else
              null;

          keyboard.enable =
            bluetooth.enable
            || (
              (builtins.hasAttr "keyboard" config.facter.report.hardware)
              && ((builtins.length config.facter.report.hardware.keyboard) > 0)
            );

          mouse.enable =
            bluetooth.enable
            || (
              (builtins.hasAttr "mouse" config.facter.report.hardware)
              && ((builtins.length config.facter.report.hardware.mouse) > 0)
            );

          bluetooth.enable =
            (builtins.hasAttr "bluetooth" config.facter.report.hardware)
            && ((builtins.length config.facter.report.hardware.bluetooth) > 0);

          logitech.enable =
            (
              (builtins.hasAttr "mouse" config.facter.report.hardware)
              && ((builtins.length config.facter.report.hardware.mouse) > 0)
              && (builtins.any (
                mouse: mouse.model == "Logitech USB Receiver"
              ) config.facter.report.hardware.mouse)
            )
            || (
              (builtins.hasAttr "keyboard" config.facter.report.hardware)
              && ((builtins.length config.facter.report.hardware.keyboard) > 0)
              && (builtins.any (
                keyboard: keyboard.model == "Logitech USB Receiver"
              ) config.facter.report.hardware.keyboard)
            );
        };
    };
in
{
  flake.nixosModules.hardware-facter =
    { lib, ... }:
    {
      imports = [ common ];

      hardware.enableAllFirmware = true;

      dot.hardware = {
        rpi."4".enable = lib.mkDefault false;
        battery.enable = lib.mkDefault false;
      };
    };

  flake.homeModules.hardware-facter =
    {
      osConfig,
      lib,
      ...
    }:
    {
      imports = [ common ];

      dot.hardware = {
        rpi."4".enable = lib.mkDefault osConfig.dot.hardware.rpi."4".enable;
        temp = lib.mkDefault osConfig.dot.hardware.temp;
        battery.enable = lib.mkDefault osConfig.dot.hardware.battery.enable;
        monitor.main = lib.mkDefault osConfig.dot.hardware.monitor.main;
      };
    };
}
