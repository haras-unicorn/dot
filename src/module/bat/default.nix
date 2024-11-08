{ pkgs, ... }:

# TODO: add pager to dot config

{
  shared.dot = {
    shell.aliases = {
      cat = "${pkgs.bat}/bin/bat";
    };
  };

  home.shared = {
    home.sessionVariables = {
      PAGER = "${pkgs.bat}/bin/bat";
    };

    programs.bat.enable = true;
    programs.bat.config = { style = "header,rule,snip,changes"; };
  };
}
