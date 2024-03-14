{ pkgs, ... }:

let
  llama-cpp = pkgs.llama-cpp.override { vulkanSupport = true; };

  say = pkgs.writeShellApplication {
    name = "say";
    runtimeInputs = [ llama-cpp ];
    text = ''
      MODEL="$1"
      if [[ ! -f "$MODEL" ]]; then
        printf "I need a model to speak.\n"
        exit 1
      fi

      llama \
        --model "$MODEL" \
        --n-gpu-layers 100 \
        --log-disable
    '';
  };
in
{
  home.packages = [
    llama-cpp
    say
  ];
}
