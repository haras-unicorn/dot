{ nixified-ai, system, ... }:

# TODO: control over platform

{
  home.shared = {
    home.packages = [
      nixified-ai.packages.${system}.invokeai-nvidia
    ];
  };
}
