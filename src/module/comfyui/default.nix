{ nix-comfyui, pkgs, ... }:

let
  comfyui = nix-comfyui.packages.${pkgs.system}.cuda-comfyui;
in
{
  home.shared = {
    home.packages = [
      comfyui
    ];
  };
}
