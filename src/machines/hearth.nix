{ self, ... }:

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
        xdg.dataFile."easyeffects/autoload/output/krk.json".source =
          "${self}/assets/easyeffects/hearth-krk-autoload.json";
        xdg.dataFile."easyeffects/output/krk.json".source = "${self}/assets/easyeffects/hearth-krk.json";

        xdg.dataFile."easyeffects/autoload/input/rode.json".source =
          "${self}/assets/easyeffects/hearth-rode-autoload.json";
        xdg.dataFile."easyeffects/input/rode.json".source = "${self}/assets/easyeffects/hearth-rode.json";

        xdg.dataFile."easyeffects/autoload/output/redmi.json".source =
          "${self}/assets/easyeffects/hearth-redmi-autoload.json";
        xdg.dataFile."easyeffects/output/redmi.json".source =
          "${self}/assets/easyeffects/hearth-redmi.json";

        xdg.configFile."obs-studio/basic/scenes/Untitled.json" = {
          force = true;
          source = "${self}/assets/obs/hearth-scene.json";
        };
      };
    };
}
