{
  machines.nixosModules.monitor =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      user = config.dot.user.user;
    in
    lib.mkIf config.hardware.facter.detection.monitor.enable {
      hardware.i2c.enable = true;
      services.ddccontrol.enable = true;

      users.users.${user}.extraGroups = [
        "i2c"
      ];
    };

  machines.homeModules.monitor =
    {
      pkgs,
      lib,
      config,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf osConfig.hardware.facter.detection.monitor.enable {
      dot.desktop.keybinds = lib.mkIf hardware.typing [
        {
          mods = [
            "super"
            "shift"
          ];
          key = "b";
          command = "${pkgs.brightnessctl}/bin/brightnessctl set +2%";
        }
        {
          mods = [ "super" ];
          key = "b";
          command = "${pkgs.brightnessctl}/bin/brightnessctl set 2%-";
        }
      ];

      home.packages = [
        pkgs.brightnessctl
        pkgs.ddcutil # NOTE: because ddccontrol might core dump with nvidia
        pkgs.ddccontrol
        pkgs.ddccontrol-db
      ];
    };
}
