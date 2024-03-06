{ pkgs, ... }:

# FIXME: https://discourse.nixos.org/t/logrotate-config-fails-due-to-missing-group-30000/28501/7

{
  boot.kernelPackages = pkgs.linuxPackages_hardened;
  services.logrotate.checkConfig = false;
}
