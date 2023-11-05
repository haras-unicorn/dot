{ pkgs, ... }:

{
  home.shellAliases = {
    find = "${pkgs.fd}/bin/fd";
  };

  home.packages = with pkgs; [ fd ];
}
