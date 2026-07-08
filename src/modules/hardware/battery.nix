{
  machines.nixosModules.power-management-upower-ppd =
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

      services.upower.enable = true;

      services.power-profiles-daemon.enable = true;
    };
}
