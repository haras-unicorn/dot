{ pkgs, ... }:

{
  home.shellAliases = {
    sed = "${pkgs.sd}/bin/sd";
  };

  home.packages = with pkgs; [ sd ];
}
