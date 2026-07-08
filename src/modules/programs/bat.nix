{
  machines.homeModules.bat =
    { config, lib, ... }:
    {
      dot.programs.pager.package = config.programs.bat.package;

      programs.bat.enable = true;
      programs.bat.config = {
        style = "header,rule,snip,changes";
      };
    };
}
