{ pkgs, config, ... }:

# TODO: output length - wrap prompt and then cut result
# TODO: chat history - make chat command that will take chat name as first argument and u put chats in ~/write/chats as UTF8 text files

let
  llama-cpp = pkgs.llama-cpp.override { vulkanSupport = true; };

  write = pkgs.writeShellApplication {
    name = "write";
    runtimeInputs = [ llama-cpp ];
    text = ''
      command="llama --prompt \"$*\" --no-display-prompt --log-disable"
      while IFS= read -r line; do
        command+=" $line"
      done < "${config.home.homeDirectory}/write/llama.options"

      sh -c "$command 2>/dev/null"
    '';
  };

  write-server = pkgs.writeShellApplication {
    name = "write-server";
    runtimeInputs = [ llama-cpp ];
    text = ''
      system="$1"
      command="llama-server --system-prompt-file "$system" --chat-template llama2 --no-display-prompt --log-disable"
      while IFS= read -r line; do
        command+=" $line"
      done < "${config.home.homeDirectory}/write/llama.options"

      sh -c "$command 2>/dev/null"
    '';
  };
in
{
  home.packages = [
    llama-cpp
    write
    write-server
  ];
}
