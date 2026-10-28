# TODO: make the list command output an actual
# line-by-line list and not a grid

{ self, ... }:

{
  self.overlays.overlays.eza.value =
    final: _prev:
    let
      baseOptions = [
        "--all"
        "--git-ignore"
      ];
      baseArgs = final.lib.escapeShellArgs baseOptions;
    in
    {
      list = final.writeShellApplication {
        name = "list";
        runtimeInputs = [ final.eza ];
        text = ''
          eza ${baseArgs} --grid "$@"
        '';
      };

      tree = final.writeShellApplication {
        name = "tree";
        runtimeInputs = [ final.eza ];
        text = ''
          eza ${baseArgs} --tree "$@"
        '';
      };
    };
}
