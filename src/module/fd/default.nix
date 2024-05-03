{ pkgs, ... }:

{
  shared = {
    dot = {
      shell.aliases = {
        find = "${pkgs.fd}/bin/fd";
      };
    };
  };

  home.shared = {
    home.packages = with pkgs; [ fd ];
  };
}
