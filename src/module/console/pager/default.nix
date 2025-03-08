{ pkgs, ... }:

{
  integrate.homeManagerModule.homeManagerModule = {
    shell.aliases = {
      cat = "${pkgs.bat}/bin/bat";
    };

    home.sessionVariables = {
      PAGER = "${pkgs.bat}/bin/bat";
    };

    programs.bat.enable = true;
    programs.bat.config = { style = "header,rule,snip,changes"; };
  };
}
