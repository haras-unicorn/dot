{
  machines.machines.hearth =
    { config, ... }:
    {
      boot.blacklistedKernelModules = [
        "amdgpu"
        "radeon"
      ];

      dot.nix.gc = false;

      dot.hardware.temperature = "/sys/class/hwmon/hwmon2/temp1_input";
      dot.hardware.display = "DP-1";

      dot.wallpaper.static = true;

      dot.location.latitude = 45.815010;
      dot.location.longitude = 15.981919;
      dot.location.altitude = 125;
      dot.location.accuracy = 30000;
      dot.location.address = "Zagreb, Croatia";

      home-manager.users.${config.dot.user.user} = {
        services.easyeffects.preset = "krk";
      };
    };
}
