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
    in
    {
      dot.programs.shell = {
        inherit list tree;
        aliases = {
          la = eza + " " + humanArgs + " --grid";
          te = eza + " " + humanArgs + " --tree";
        };
      };

      programs.eza.enable = true;
      programs.eza.extraOptions = humanOptions;
    };
}
