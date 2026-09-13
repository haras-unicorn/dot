# TODO: make the list command output an actual
# line-by-line list and not a grid

{
  self.homeModules.eza.value =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      eza = lib.getExe config.programs.eza.package;

      humanOptions = [
        "--all"
        "--git-ignore"
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
        list = pkgs.harasPackages.list;
        tree = pkgs.harasPackages.tree;
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
