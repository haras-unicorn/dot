# TODO: make the list command output an actual
# line-by-line list and not a grid

{
  machines.homeModules.eza =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      eza = lib.getExe config.programs.eza.package;

      baseOptions = [
        "--all"
        "--git-ignore"
      ];
      baseArgs = lib.escapeShellArgs baseOptions;

      humanOptions = baseOptions ++ [
        "--group-directories-first"
        "--color=always"
        "--icons"
        "--group"
        "--header"
        "--long"
      ];
      humanArgs = lib.escapeShellArgs humanOptions;
    in
    {
      dot.commands = {
        list = pkgs.writeShellApplication {
          name = "list";
          runtimeInputs = [ config.programs.eza.package ];
          text = ''
            eza ${baseArgs} --grid "$@"
          '';
        };

        tree = pkgs.writeShellApplication {
          name = "tree";
          runtimeInputs = [ config.programs.eza.package ];
          text = ''
            eza ${baseArgs} --tree "$@"
          '';
        };
      };

      dot.programs.shell = {
        aliases = {
          la = eza + " " + humanArgs + " --grid";
          te = eza + " " + humanArgs + " --tree";
        };
      };

      programs.eza.enable = true;
      programs.eza.extraOptions = humanOptions;
    };
}
