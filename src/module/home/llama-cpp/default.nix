{ pkgs, config, ... }:

let
  llama-cpp = pkgs.llama-cpp.override { vulkanSupport = true; };

  write = pkgs.writeShellApplication {
    name = "write";
    runtimeInputs = [ llama-cpp pkgs.glow ];
    text = ''
      set +u
      chat_name="$1"
      if [[ "$chat_name" == "" ]]; then
        chat_name="default"
      fi
      shift
      set -u

      chat_file="${config.home.homeDirectory}/llama/$chat_name.md"
      if [[ ! -f "$chat_file" ]]; then
        touch "$chat_file"
      fi
      chat="$(cat "$chat_file")"

      command="llama --prompt \"$chat\n$*\""
      command="$command --color --no-display-prompt --log-disable"
      while IFS= read -r line; do
        command+=" $line"
      done < "${config.home.homeDirectory}/llama/write.options"

      printf "%s" "$chat" | glow
      sh -c "$command 2>/dev/null" | \
        tee --append "$chat_file" | \
        glow
    '';
  };

  chat = pkgs.writeShellApplication {
    name = "chat";
    runtimeInputs = [ llama-cpp ];
    text = ''
      set +u
      chat_name="$1"
      if [[ "$chat_name" == "" ]]; then
        chat_name="default"
      fi
      shift
      set -u

      chat_file="${config.home.homeDirectory}/llama/$chat_name.md"
      if [[ ! -f "$chat_file" ]]; then
        touch "$chat_file"
      fi
      chat="$(cat "$chat_file")"

      command="llama --interactive-first --prompt \"$chat\""
      command="$command --color --no-display-prompt --log-disable"
      while IFS= read -r line; do
        command+=" $line"
      done < "${config.home.homeDirectory}/llama/chat.options"

      printf "%s" "$chat"
      cat | tee --append "$chat_file" | \
        sh -c "$command 2>/dev/null" | \
        tee --append "$chat_file"
    '';
  };

  journal = pkgs.writeShellApplication {
    name = "journal";
    runtimeInputs = [ llama-cpp pkgs.mods ];
    text = ''
      command="llama-server"
      command="$command --color --no-display-prompt --log-disable"
      while IFS= read -r line; do
        command+=" $line"
      done < "${config.home.homeDirectory}/llama/journal.options"

      sh -c "$command &>/dev/null" &
      mods
    '';
  };
in
{
  home.packages = [
    llama-cpp
    write
    chat
    journal
  ];
}
