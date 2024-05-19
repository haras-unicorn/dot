{ nixified-ai, system, ... }:

# TODO: control over platform
# FIXME: Package ‘python3.11-dependency-injector-4.41.0’ is marked as broken, refusing to evaluate.

{
  home.shared = {
    home.packages = [
      nixified-ai.packages.${system}.invokeai-nvidia
    ];
  };
}
