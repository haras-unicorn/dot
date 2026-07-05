{
  machines.nixosModules.power-management-tlp =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    lib.mkIf config.dot.hardware.battery {
      environment.systemPackages = [ pkgs.powertop ];

      powerManagement.enable = true;
      powerManagement.powertop.enable = true;

      services.tlp.enable = true;
      services.tlp.settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        START_CHARGE_THRESH_BAT0 = 40;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };
}
