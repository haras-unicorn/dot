{
  shared = {
    dot = {
      hardware.rpi."4".enable = true;
      hardware.temp = "/sys/class/hwmon/hwmon0/temp1_input";

      ddns.coordinator.enable = true;
      vpn.coordinator.enable = true;
      db.coordinator.enable = true;
    };
  };
}
