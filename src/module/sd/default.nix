{ pkgs, ... }:

{
  shared = {
    dot = {
      shell.aliases = {
        sed = "${pkgs.sd}/bin/sd";
      };
    };
  };

  home.shared = {
    home.packages = with pkgs; [ sd ];
  };
}
