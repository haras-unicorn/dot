{ pkgs, ... }:

# FIXME: integrate with hardware?

{
  home.packages = with pkgs; [
    lm_sensors
    dua
    duf
    dust
    vulkan-tools
    glxinfo
    pciutils
    lsof
    dmidecode
    inxi
    hwinfo
    htop
    nvtop
    tokei
    dog
  ];
}
