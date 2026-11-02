{ selfLib, ... }:

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

      humanOptions = selfLib.eza.baseOptions ++ [
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
