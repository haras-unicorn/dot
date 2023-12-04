{ pkgs, ... }:

# FIXME: when using rt kernel: Failed PREEMPT_RT sanity check. Bailing out!

# NOTE: https://github.com/musnix/musnix

{
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernel.sysctl = { "vm.swappiness" = 10; };
  boot.kernelParams = [ "threadirq" ];

  powerManagement.cpuFreqGovernor = "performance";

  services.das_watchdog.enable = true;
  services.ananicy.enable = true;
  services.earlyoom.enable = true;
  services.irqbalance.enable = true;

  security.rtkit.enable = true;
}
