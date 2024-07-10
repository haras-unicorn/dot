{ pkgs, ... }:

{
  home.shared = {
    home.packages = [
      pkgs.zed-editor
    ];
  };
}
