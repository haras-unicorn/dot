{ pkgs, ... }:

let
  comfyui = pkgs.comfyuiPackages.comfyui.override {
    platform = "cuda";
  };
in
{
  home.shared = {
    home.packages = [
      comfyui
    ];
  };
}
