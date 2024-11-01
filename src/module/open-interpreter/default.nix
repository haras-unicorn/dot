{ pkgs, config, ... }:

let
  open-interpreter = pkgs.writeShellApplication {
    name = "interpreter";
    runtimeInputs = [ pkgs.open-interpreter ];
    text = ''
      interpreter -ak "$(cat ${config.home.homeDirectory}/.openai/api.key)" "$@"
    '';
  };
in
{
  home = {
    home.packages = [
      open-interpreter
    ];
  };
}
