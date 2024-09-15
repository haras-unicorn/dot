{ pkgs, config, ... }:

let
  aider = pkgs.writeShellApplication {
    name = "aider";
    runtimeInputs = [ pkgs.aider-chat ];
    text = ''
      if [ -f ${config.home.homeDirectory}/.openai/api.key ]; then
        export OPENAI_API_KEY=$(cat ${config.home.homeDirectory}/.openai/api.key)
        export AIDER_MINI=1
      fi

      aider $@
    '';
  };
in
{
  home = {
    shared = {
      home.packages = [
        aider
      ];
    };
  };
}
