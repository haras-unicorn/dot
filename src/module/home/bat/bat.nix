{ ... }:

{
  programs.bat.enable = true;
  programs.bat.config = { style = "header,rule,snip,changes"; };

  home.sessionVariables = {
    PAGER = "bat";
  };
  home.shellAliases = {
    cat = "bat";
  };
}
