{ pkgs, ... }:

{
  shared = {
    dot = {
      shell.aliases = {
        sed = "${pkgs.sd}/bin/sd";
      };
    };
  };

  home = {
    home.packages = with pkgs; [ sd ];
  };
}
