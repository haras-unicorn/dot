{ pkgs, ... }:

{
  programs.bat.enable = true;
  programs.bat.config = { style = "header,rule,snip,changes"; };

  de.sessionVariables = {
    PAGER = "${pkgs.bat}/bin/bat";
  };
  home.shellAliases = {
    cat = "${pkgs.bat}/bin/bat";
  };
}
