{
  shared = {
    dot = {
      hardware.rpi."4".enable = true;
      hardware.temp = "/sys/class/hwmon/hwmon0/temp1_input";
      vpn.lighthouse.enable = true;
    };
  };
}
