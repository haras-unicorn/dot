{ pkgs, config, ... }:

let
  aichat = pkgs.writeShellApplication {
    name = "aichat";
    runtimeInputs = [ pkgs.aichat ];
    text = ''
      cat <<EOF >${config.xdg.configHome}/aichat/config.yaml
      api_key: $(cat ${config.home.homeDirectory}/.openai/api.key)
      ${builtins.readFile ./config.yaml}
      EOF
      chmod 600 ${config.xdg.configHome}/aichat/config.yaml

      aichat "$@"
    '';

  };
in
{
  home.packages = [ aichat ];

  xdg.configFile."aichat/roles.yaml".source = ./roles.yaml;
}
