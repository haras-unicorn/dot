{ selfLib, ... }:

{
  self.overlays.overlays.eza.value =
    final: _prev:
    let
      baseArgs = final.lib.escapeShellArgs selfLib.eza.baseOptions;
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
