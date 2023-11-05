{ pkgs, ... }:

{
  home.packages = with pkgs; [
    lm_sensors
    ncdu
    glxinfo
    pciutils
    lsof
    dmidecode
    inxi
    hwinfo
  ];
}
