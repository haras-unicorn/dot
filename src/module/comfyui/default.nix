{ pkgs, ... }:

{
  home.shared = {
    home.packages = [
      pkgs.comfyuiPackages.comfyui-with-extensions
    ];
  };
}
