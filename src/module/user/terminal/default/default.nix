{ pkgs, ... }:

# NOTE: install everywhere to enable full ssh compatibility

{
  home = {
    home.packages = [
      pkgs.xfce.xfce4-terminal
    ];
  };
}
