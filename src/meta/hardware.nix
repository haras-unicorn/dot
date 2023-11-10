{ lib, ... }:

with lib;
{
  options.dot.hardware = {
    ram = mkOption {
      type = with types; ints.u8;
      description = "cat /proc/meminfo";
      example = 4;
    };
    mainMonitor = mkOption {
      type = with types; str;
      description = ''
        xrandr --query
        hyprctl monitors
        swaymsg -t get_outputs
      '';
      example = "DP-1";
    };
    monitors = mkOption {
      type = with types; listOf str;
      description = ''
        xrandr --query
        hyprctl monitors
        swaymsg -t get_outputs
      '';
      example = [ "DP-1" ];
    };
    networkInterface = mkOption {
      type = with types; str;
      description = "ip address";
      example = "enp27s0";
    };
    cpuHwmon = mkOption {
      type = with types; str;
      description = "ls /sys/class/hwmon";
      example = "/sys/class/hwmon/hwmon1/temp1_input";
    };
    soundcardPciId = mkOption {
      type = with types; str;
      description = "lspci | grep -i audio";
      example = "2b:00.3";
    };
    nvidiaDriver.version = mkOption {
      type = with types; str;
      description = "https://nixos.wiki/wiki/Nvidia";
      default = "vulkan_beta";
      example = "legacy_470";
    };
    nvidiaDriver.open = mkOption {
      type = with types; bool;
      description = "https://nixos.wiki/wiki/Nvidia";
      default = true;
      example = false;
    };
  };

  config = { };
}
