{ pkgs, ... }:

# FIXME: integrate with hardware (especially nvtop)

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
    htop
    nvtop
  ];
}
