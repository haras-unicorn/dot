{ pkgs, ... }:

{
  shared = {
    dot = {
      shell.aliases = {
        # NOTE: find is a nushell command
        # find = "${pkgs.fd}/bin/fd";
      };
    };
  };

  home = {
    home.packages = with pkgs; [ fd ];
  };
}
