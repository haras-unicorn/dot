{ pkgs, ... }:

# FIXME: integrate with hardware?

{
  home.packages = with pkgs; [
    lm_sensors
    dua
    duf
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
