{ pkgs, ... }:

{
  home.shared = {
    shell.aliases = {
      find = "${pkgs.fd}/bin/fd";
    };

    home.packages = with pkgs; [ fd ];
  };
}
