{ pkgs, config, ... }:

let
  llama-cpp = pkgs.llama-cpp.override { vulkanSupport = true; };

  write = pkgs.writeShellApplication {
    name = "write";
    runtimeInputs = [ llama-cpp ];
    text = ''
      command="llama --prompt '$*' --no-display-prompt --log-disable"
      while IFS= read -r line; do
        command+=" $line"
      done < "${config.home.homeDirectory}/write/llama.options"
      echo "$command"

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
