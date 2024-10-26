{ nix-comfyui, pkgs, ... }:

# TODO: pick cuda/rocm based on cudaSupport

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
