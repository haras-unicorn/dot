{ nix-comfyui, pkgs, ... }:

{
  home.shared = {
    home.packages = [
      nix-comfyui.packages.${pkgs.system}.cuda.comfyui
    ];
  };
}
