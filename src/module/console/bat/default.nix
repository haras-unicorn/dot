{ pkgs, ... }:

{
  shared.dot = {
    shell.aliases = {
      cat = "${pkgs.bat}/bin/bat";
    };
  };

  home = {
    home.sessionVariables = {
      PAGER = "${pkgs.bat}/bin/bat";
    };

    programs.bat.enable = true;
    programs.bat.config = { style = "header,rule,snip,changes"; };
  };
}
