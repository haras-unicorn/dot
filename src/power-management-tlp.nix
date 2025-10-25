{
  pkgs,
  lib,
  config,
  ...
}:

let
  hasBattery = config.dot.hardware.battery.enable;
in
{
  branch.nixosModule.nixosModule = lib.mkMerge [
    {
      powerManagement.enable = true;
      powerManagement.powertop.enable = true;
      environment.systemPackages = [ pkgs.powertop ];
    }
    (lib.mkIf hasBattery {
      services.tlp.enable = true;
      services.tlp.settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        START_CHARGE_THRESH_BAT0 = 40;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    })
  ];
}
