{ self, ... }:

{
  self.overlays.overlays.theme.value = final: _prev: {
    inspect-gtk = final.writeShellApplication {
      name = "inspect-gtk";
      text = ''
        export GTK_DEBUG=interactive
        exec "$@"
      '';
    };

    inspect-qt = final.writeShellApplication {
      name = "inspect-qt";
      runtimeInputs = [ final.gammaray ];
      text = ''
        exec gammaray "$@"
      '';
    };
  };
}
