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

      home-manager.users.${config.dot.user.user} = {
        services.easyeffects.preset = "krk";
      };
    };
}
