{ pkgs, ... }:

# TODO: add pager to dot config

{
  shared.dot = {
    desktopEnvironment.sessionVariables = {
      PAGER = "${pkgs.bat}/bin/bat";
    };
  };

  home.shared = {
    shell.aliases = {
      cat = "${pkgs.bat}/bin/bat";
    };

    programs.bat.enable = true;
    programs.bat.config = { style = "header,rule,snip,changes"; };
  };
}
