{ pkgs, config, ... }:

let
  aichat = pkgs.writeShellApplication {
    name = "aichat";
    runtimeInputs = [ pkgs.aichat ];
    text = ''
      cat <<EOF >${config.xdg.configHome}/aichat/config.yaml
        api_key: $(cat ${config.home.homeDirectory}/.openai/api.key)
        save: true
      EOF

      aichat "$@"
    '';

  };
in
{
  home.packages = [ aichat ];
}
