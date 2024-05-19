{ nixified-ai, ... }:

# TODO: control over platform

{
  home.shared = {
    home.packages = [
      nixified-ai.packages.invokeai-nvidia
    ];
  };
}
