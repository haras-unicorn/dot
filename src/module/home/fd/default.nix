{ pkgs, ... }:

{
  shell.aliases = {
    find = "${pkgs.fd}/bin/fd";
  };

  home.packages = with pkgs; [ fd ];
}
