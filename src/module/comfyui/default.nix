{ nix-comfyui, pkgs, config, ... }:

let
  packageName =
    if config.nixpkgs.config.cudaSupport then
      "cuda-comfyui-with-extensions"
    else if config.nixpkgs.config.rocmSupport then
      "rocm-comfyui-with-extensions"
    else
      "comfyui-with-extensions";

  package = nix-comfyui.packages.${pkgs.system}.${packageName};

  comfyui = pkgs.writeShellApplication {
    name = "comfyui";
    runtimeInputs = [ package ];
    text = ''
      mkdir -p "${config.xdg.dataHome}/comfyui"
      cd "${config.xdg.dataHome}/comfyui"
      comfyui --preview-method taesd "$@"
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
