{ nix-comfyui, pkgs, config, ... }:

# TODO: pick cuda/rocm based on cudaSupport

let
  comfyui = pkgs.writeShellApplication {
    name = "comfyui";
    runtimeInputs = nix-comfyui.packages.${pkgs.system}.cuda-comfyui;
    text = ''
      mkdir -p "${config.xdg.dataHome}/comfyui"
      cd "${config.xdg.dataHome}/comfyui"
      comfyui "$@"
    '';
  };
in
{
  home.shared = {
    home.packages = [
      comfyui
    ];
  };
}
