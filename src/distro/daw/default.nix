{ pkgs, ... }:

# TODO: https://github.com/mzuther/Squeezer
# FIXME: surge-XT wrong hash
# FIXME: distrho build error
# FIXME: helm build error

{
  home.shared = {
    home.packages = with pkgs; [
      ardour
      zrythm
      audacity
      carla
      yabridge
      supercollider
      helio-workstation

      # distrho
      lsp-plugins
      # surge-XT
      cardinal
      fire
      paulstretch
      zynaddsubfx
      yoshimi
      # helm
      vital
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
  };
}
