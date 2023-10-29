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
    geonkick
    wolf-shaper
    dragonfly-reverb
    zam-plugins
    qsampler
    samplv1
    synthv1
    padthv1
    drumkv1
    talentedhack
  ];
}
