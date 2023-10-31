{ pkgs, ... }:

let
  open-interpreter = pkgs.writeShellApplication {
    name = "interpreter";
    runtimeInputs = [ pkgs.open-interpreter ];
    text = ''
      interpreter -ak "$(cat ~/.openai/api.key)"
    '';
  };
in
{
  home.packages = [
    open-interpreter
  ];
}
