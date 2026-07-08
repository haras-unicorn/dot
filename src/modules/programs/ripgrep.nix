{
  machines.homeModules.ripgrep =
    { lib, config, ... }:
    {
      dot.programs.shell.aliases = {
        grep = lib.getExe config.programs.ripgrep.package;
      };

      programs.ripgrep.enable = true;
      programs.ripgrep.arguments = [
        "--max-columns=100"
        "--max-columns-preview"
        "--smart-case"
      ];
    };
}
