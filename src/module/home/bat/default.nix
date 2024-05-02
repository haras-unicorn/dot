{ pkgs, ... }:

{
  home.shared = {
    de.sessionVariables = {
      PAGER = "${pkgs.bat}/bin/bat";
    };

    shell.aliases = {
      cat = "${pkgs.bat}/bin/bat";
    };

    programs.bat.enable = true;
    programs.bat.config = { style = "header,rule,snip,changes"; };
  };
}
