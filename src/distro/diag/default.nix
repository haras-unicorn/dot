{ pkgs, ... }:

{
  home.packages = with pkgs; [
    lm_sensors # NOTE: get sensor information
    dua # NOTE: get disk space usage interactively
    duf # NOTE: disk space usage overview
    du-dust # NOTE: disk space usage in a tree
    pciutils # NOTE: lspci
    lsof # NOTE: lsof -ni for ports
    dmidecode # NOTE: sudo dmidecode for mobo info
    inxi # NOTE: overall hardware info
    hwinfo # NOTE: overall hardware info
    htop # NOTE: CPU process manager
    tokei # NOTE: count lines of code
    dog # NOTE: dns client
    upower # NOTE: battery power
  ];
}
