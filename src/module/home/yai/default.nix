{ pkgs, config, ... }:

let
  mkConfig = model: mode: role:
    builtins.toJSON
      (builtins.fromJSON ((builtins.readFile ./config.jsonc)) // {
        openai_key = "$(cat ${config.home.homeDirectory}/.openai/api.key)";
        openai_model = model;
        user_default_prompt_mode = mode;
        user_preferences = role;
      });

  mkYai = name: model: mode: role:
    pkgs.writeShellApplication {
      name = "${name}";
      runtimeInputs = [ pkgs.yai ];
      text = ''
        cat <<EOF >${config.xdg.configHome}/yai.json
        ${mkConfig model mode role}
        EOF
        chmod 600 ${config.xdg.configHome}/yai.json

        yai "$@"
      '';
    };

  yai3 = mkYai "yai3" "gpt-3.5-turbo-1106" "chat" "";
  yai4 = mkYai "yai4" "gpt-4-1106-preview" "chat" "";
in
{
  home.shared = {
    home.packages = [ yai3 yai4 ];
  };
}
