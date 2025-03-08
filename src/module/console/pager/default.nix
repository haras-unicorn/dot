{ pkgs, ... }:

{
  config = {
    shell.aliases = {
      cat = "${pkgs.bat}/bin/bat";
    };
  };

  integrate.homeManagerModule.homeManagerModule = {
    home.sessionVariables = {
      PAGER = "${pkgs.bat}/bin/bat";
    };

    programs.bat.enable = true;
    programs.bat.config = { style = "header,rule,snip,changes"; };
  };
}
