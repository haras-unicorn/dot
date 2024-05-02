{ pkgs, config, ... }:

let
  mkAichat = name: model:
    pkgs.writeShellApplication {
      name = "${name}";
      runtimeInputs = [ pkgs.aichat ];
      text = ''
        cat <<EOF >${config.xdg.configHome}/aichat/config.yaml
        api_key: $(cat ${config.home.homeDirectory}/.openai/api.key)
        ${builtins.readFile ./config.yaml}
        EOF
        chmod 600 ${config.xdg.configHome}/aichat/config.yaml

        aichat --model ${model} "$@"
      '';
    };

  aichat3 = mkAichat "aichat3" "gpt-3.5-turbo";
  aichat4 = mkAichat "aichat4" "gpt-4";
in
{
  home.shared = {
    home.packages = [ aichat3 aichat4 ];

    xdg.configFile."aichat/roles.yaml".source = ./roles.yaml;
  };
}
