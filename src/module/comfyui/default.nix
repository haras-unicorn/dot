{ nix-comfyui, pkgs, config, ... }:

let
  packageName =
    if builtins.hasAttr "cudaSupport" config.nixpkgs.config then
      "cuda-comfyui-with-extensions"
    else if builtins.hasAttr "rocmSupport" config.nixpkgs.config then
      "rocm-comfyui-with-extensions"
    else
      "comfyui-with-extensions";

  hasAnyPlatform =
    if builtins.hasAttr "cudaSupport" config.nixpkgs.config then
      true
    else if builtins.hasAttr "rocmSupport" config.nixpkgs.config then
      true
    else
      false;

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
      (pkgs.lib.mkIf hasAnyPlatform comfyui)
    ];
  };
}
