{ pkgs, ... }:

{
  home.packages = with pkgs; [
    lmms
    ardour
    zrythm
    audacity
    carla
    yabridge

    distrho
    lsp-plugins
    surge-XT
    cardinal
    fire
    paulstretch
    zynaddsubfx
    yoshimi
    helm
  ];
}
