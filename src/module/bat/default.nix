{ pkgs, ... }:

# TODO: add pager to dot config

{
  shared.dot = {
    desktopEnvironment.sessionVariables = {
      PAGER = "${pkgs.bat}/bin/bat";
    };

    shell.aliases = {
      cat = "${pkgs.bat}/bin/bat";
    };
  };

  home.shared = {
    programs.bat.enable = true;
    programs.bat.config = { style = "header,rule,snip,changes"; };
  };
}
