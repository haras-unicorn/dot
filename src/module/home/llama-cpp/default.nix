{ pkgs, config, ... }:

# TODO: output length - wrap prompt and then cut result
# TODO: chat history - make chat command that will take chat name as first argument and u put chats in ~/write/chats as UTF8 text files

let
  llama-cpp = pkgs.llama-cpp.override { vulkanSupport = true; };

  write = pkgs.writeShellApplication {
    name = "write";
    runtimeInputs = [ llama-cpp ];
    text = ''
      set +e
      chat_name="$1"
      if [[ "$chat_name" == "" ]]; then
        chat_name="default"
      fi
      set -e

      chat_file="${config.home.homeDirectory}/llama/$chat_name.chat"
      if [[ ! -f "$chat_file" ]]; then
        touch "$chat_file"
      fi
      chat="$(cat "$chat_file")"
      shift

      command="llama --prompt \"$chat\n$*\""
      command="$command --color --no-display-prompt --log-disable"
      while IFS= read -r line; do
        command+=" $line"
      done < "${config.home.homeDirectory}/llama/write.options"

      echo -e "$chat"
      sh -c "$command 2>/dev/null" | tee --append "$chat_file"
    '';
  };

  chat = pkgs.writeShellApplication {
    name = "chat";
    runtimeInputs = [ llama-cpp ];
    text = ''
      set +e
      chat_name="$1"
      if [[ "$chat_name" == "" ]]; then
        chat_name="default"
      fi
      set -e

      chat_file="${config.home.homeDirectory}/llama/$chat_name.chat"
      if [[ ! -f "$chat_file" ]]; then
        touch "$chat_file"
      fi
      chat="$(cat "$chat_file")"
      shift

      command="llama --interactive-first --prompt \"$chat\""
      command="$command --color --no-display-prompt --log-disable"
      while IFS= read -r line; do
        command+=" $line"
      done < "${config.home.homeDirectory}/llama/chat.options"

      echo -e "$chat"
      cat | tee --append "$chat_file" | sh -c "$command 2>/dev/null" | tee --append "$chat_file" 
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
