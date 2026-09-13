{ self, ... }:

{
  self.overlays.overlays.playerctl.value = final: _prev: {
    play-pause = final.writeShellApplication {
      name = "playerctl-play-pause";
      runtimeInputs = [ final.playerctl ];
      text = ''
        exec playerctl play-pause "$@"
      '';
    };
  };
}
