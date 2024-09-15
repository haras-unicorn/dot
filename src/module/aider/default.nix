{ pkgs, config, ... }:

let
  aider = pkgs.writeShellApplication {
    name = "aider";
    runtimeInputs = [ pkgs.aider-chat ];
    text = ''
      if [ -f ${config.home.homeDirectory}/.openai/api.key ]; then
        OPENAI_API_KEY=$(cat ${config.home.homeDirectory}/.openai/api.key)
        AIDER_MINI=1

        export OPENAI_API_KEY;
        export AIDER_MINI;
      fi

      aider "$@"
    '';
  };
in
{
  home = {
    shared = {
      home.packages = [
        aider
      ];

      home.file.".aider.conf.yml".source = ./config.yaml;
    };
  };
}
