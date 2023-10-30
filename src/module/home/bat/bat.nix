{ pkgs, ... }:

{
  programs.bat.enable = true;
  programs.bat.config = { style = "header,rule,snip,changes"; };

  home.sessionVariables = {
    PAGER = "${pkgs.bat}/bin/bat";
  };
  home.shellAliases = {
    cat = "${pkgs.bat}/bin/bat";
  };
}
