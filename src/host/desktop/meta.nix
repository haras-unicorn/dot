{
  groups = [ "libvirtd" "docker" "podman" "video" ];
  hardware = {
    ram = 32;
    mainMonitor = "DP-1";
    monitors = [ "DP-1" ];
    networkInterface = "enp27s0";
    hwmon = "/sys/class/hwmon/hwmon1/temp1_input";
  };
}
