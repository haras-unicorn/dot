{
  self.nixosModules.bluetooth-blueman.value =
    { config, lib, ... }:
    lib.mkIf config.hardware.facter.detection.bluetooth.enable {
      hardware.bluetooth.enable = true;
      services.blueman.enable = true;
    };

  self.homeModules.bluetooth-blueman.value =
    { osConfig, lib, ... }:
    lib.mkIf (osConfig.hardware.facter.detection.bluetooth.enable && osConfig.dot.hardware.graphics) {
      dot.desktop.windowrules = [
        {
          rule = "float";
          selector = "class";
          arg = ".blueman-manager-wrapped";
        }
      ];

      services.blueman-applet.enable = true;
    };
}
