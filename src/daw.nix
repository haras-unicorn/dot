{
  config,
  lib,
  pkgs,
  ...
}:

let
  hasSound = config.dot.hardware.sound.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
  hasMinCpu = config.dot.hardware.threads >= 8;
  hasMinMem = config.dot.hardware.memory / 1000 / 1000 / 1000 >= 16;
in
{
  branch.homeManagerModule.homeManagerModule =
    lib.mkIf (hasSound && hasMonitor && hasMinCpu && hasMinMem)
      {
        home.packages = with pkgs; [
          # classic daw
          zrythm
          qtractor

          # modular synth daw
          bespokesynth

          # patch bay
          carla
          cardinal

          # synth
          surge-XT
          helm
          odin2
          zynaddsubfx

          # drum machine
          giada
          hydrogen

          # fx
          wolf-shaper
          dragonfly-reverb
          rubberband
          paulstretch
          talentedhack

          # fx suites
          calf
          lsp-plugins
          x42-plugins
          zam-plugins
          eq10q
          mda_lv2
        ];
      };
}
