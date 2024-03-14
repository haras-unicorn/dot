{ pkgs, ... }:

let
  llama-cpp = pkgs.llama-cpp.override { vulkanSupport = true; };

  write = pkgs.writeShellApplication {
    name = "write";
    runtimeInputs = [ llama-cpp ];
    text = ''
      MODEL="$1"
      if [[ ! -f "$MODEL" ]]; then
        printf "I need a model to write.\n"
        exit 1
      fi

      PROMPT="$2"
      if [[ "$PROMPT" == "" ]]; then
        printf "I need a prompt to write.\n"
      fi

      llama \
        --model "$MODEL" \
        --prompt "$PROMPT" \
        --n-gpu-layers 100 \
        --n-predict 200 \
        --no-display-prompt \
        --log-disable \
        2>/dev/null
    '';
  };
in
{
  home.packages = [
    llama-cpp
    write
  ];
}
