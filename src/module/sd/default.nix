{ pkgs, ... }:

{
  home.shared = {
    shell.aliases = {
      sed = "${pkgs.sd}/bin/sd";
    };

    home.packages = with pkgs; [ sd ];
  };
}
