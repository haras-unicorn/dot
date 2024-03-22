{ pkgs, config, ... }:

# TODO: output length - wrap prompt and then cut result
# TODO: chat history - make chat command that will take chat name as first argument and u put chats in ~/write/chats as UTF8 text files

let
  llama-cpp = pkgs.llama-cpp.override { vulkanSupport = true; };

  write = pkgs.writeShellApplication {
    name = "write";
    runtimeInputs = [ llama-cpp ];
    text = ''
      shift
      chat_file="${config.home.homeDirectory}/llama/$1.chat"
      if [[ ! -f "$chat_file" ]]; then
        touch "$chat_file"
      fi
      chat="$(cat "$chat_file")"

      command="llama --verbose-prompt --prompt \"$chat\n$*\""
      command="$command --color --no-display-prompt --log-disable"
      while IFS= read -r line; do
        command+=" $line"
      done < "${config.home.homeDirectory}/llama/write.options"

      sh -c "$command"
    '';
  };

  chat = pkgs.writeShellApplication {
    name = "chat";
    runtimeInputs = [ llama-cpp ];
    text = ''
      shift
      chat_file="${config.home.homeDirectory}/llama/$1.chat"
      if [[ ! -f "$chat_file" ]]; then
        touch "$chat_file"
      fi
      chat="$(cat "$chat_file")"

      command="llama --interactive --verbose-prompt --prompt \"$chat\""
      command="$command --color --no-display-prompt --log-disable"
      while IFS= read -r line; do
        command+=" $line"
      done < "${config.home.homeDirectory}/llama/chat.options"

      cat | sh -c "$command" | tee "$chat_file" 
    '';
  };
in
{
  home.packages = [
    llama-cpp
    write
    chat
  ];
}
