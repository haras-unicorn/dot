{
  flake.homeModules.programs-ripgrep =
    { pkgs, ... }:
    {
      dot.shell.aliases = {
        grep = "${pkgs.ripgrep}/bin/rg";
      };

      programs.ripgrep.enable = true;
      programs.ripgrep.arguments = [
        "--max-columns=100"
        "--max-columns-preview"
        "--smart-case"
      ];
    };
}
