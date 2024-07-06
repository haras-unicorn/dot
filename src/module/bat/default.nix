{ pkgs, ... }:

# TODO: add pager to dot config

{
  home.shared = {
    desktopEnvironment.sessionVariables = {
      PAGER = "${pkgs.bat}/bin/bat";
    };

    shell.aliases = {
      cat = "${pkgs.bat}/bin/bat";
    };

    programs.bat.enable = true;
    programs.bat.config = { style = "header,rule,snip,changes"; };
  };
}
