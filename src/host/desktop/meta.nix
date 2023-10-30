{
  groups = [ "libvirtd" "docker" "podman" "video" "audio" ];
  shell = {
    pkg = "nushell";
    bin = "nu";
  };
  editor = {
    pkg = "helix";
    bin = "hx";
  };
  visual = {
    pkg = "codium-fhs";
    bin = "codium";
  };
  browser = {
    pkg = "firefox";
    bin = "firefox";
  };
  hardware = {
    ram = 32;
    mainMonitor = "DP-1";
    monitors = [ "DP-1" ];
    networkInterface = "enp27s0";
    hwmon = "/sys/class/hwmon/hwmon1/temp1_input";
    soundcardPciId = "2b:00.3";
  };
  gnupg = {
    flavor = "gtk2";
    package = "pinentry-gtk2";
    bin = "pinentry-gtk-2";
  };
}
