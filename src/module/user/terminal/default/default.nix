{ pkgs, ... }:

{
  home = {
    home.packages = [
      # NOTE: install everywhere to enable full ssh compatibility
      pkgs.kitty
      pkgs.xfce.xfce4-terminal
    ];
  };
}
