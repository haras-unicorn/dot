{ pkgs, config, ... }:

let
  llama-cpp = (pkgs.llama-cpp.override { vulkanSupport = true; }).overrideAttrs (final: prev: {
    buildInputs = (prev.buildInputs or [ ]) ++ [
      pkgs.shaderc
    ];
  });
  koboldcpp = (pkgs.koboldcpp.override { vulkanSupport = true; }).overrideAttrs (final: prev: {
    buildInputs = (prev.buildInputs or [ ]) ++ [
      pkgs.shaderc
    ];
  });

  write = pkgs.writeShellApplication {
    name = "write";
    runtimeInputs = [ llama-cpp ];
    text = ''
      set +u
      chat_name="$1"
      if [[ "$chat_name" == "" ]]; then
        chat_name="default"
      fi
      shift
      set -u

      chat_file="${config.xdg.dataHome}/llama/$chat_name.md"
      if [[ ! -f "$chat_file" ]]; then
        touch "$chat_file"
      fi
      chat="$(cat "$chat_file")"

      command="llama --prompt \"$chat\n$*\""
      command="$command --color --log-disable"
      while IFS= read -r line; do
        command+=" $line"
      done < "${config.xdg.dataHome}/llama/write.options"

      printf "%s" "$chat"
      sh -c "$command 2>/dev/null" | \
        tee --append "$chat_file"
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

      chat_file="${config.xdg.dataHome}/llama/$chat_name.md"
      if [[ ! -f "$chat_file" ]]; then
        touch "$chat_file"
      fi
      chat="$(cat "$chat_file")"

      command="llama --interactive-first --prompt \"$chat\""
      command="$command --color --no-display-prompt --log-disable"
      while IFS= read -r line; do
        command+=" $line"
      done < "${config.xdg.dataHome}/llama/chat.options"

      printf "%s" "$chat"
      cat | tee --append "$chat_file" | \
        sh -c "$command 2>/dev/null" | \
        tee --append "$chat_file"
    '';
  };

  journal = pkgs.writeShellApplication {
    name = "journal";
    runtimeInputs = [ llama-cpp ];
    text = ''
      command="llama-server --chat-template llama2"
      command="$command --no-display-prompt --log-disable"
      while IFS= read -r line; do
        command+=" $line"
      done < "${config.xdg.dataHome}/llama/journal.options"

      sh -c "$command &>/dev/null" &
    '';
  };
in
{
  system = {
    networking.firewall.allowedTCPPorts = [
      5001 # koboldcpp
    ];
  };

  home = {
    home.packages = [
      koboldcpp
      llama-cpp
      write
      chat
      journal
    ];
  };
}
