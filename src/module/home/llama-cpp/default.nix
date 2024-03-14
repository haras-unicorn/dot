{ pkgs, config, ... }:

let
  llama-cpp = pkgs.llama-cpp.override { vulkanSupport = true; };

  write = pkgs.writeShellApplication {
    name = "write";
    runtimeInputs = [ llama-cpp ];
    text = ''
      prompt="$1"
      if [[ "$prompt" == "" ]]; then
        printf "I need a prompt to write.\n"
      fi

      command="llama --prompt \"$prompt\" --no-display-prompt --log-disable"
      while IFS= read -r line; do
        command+=" $line"
      done < "${config.home.homeDirectory}/write/llama.options"

      $command 2>/dev/null
    '';
  };
in
{
  home.packages = [
    llama-cpp
    write
  ];
}
