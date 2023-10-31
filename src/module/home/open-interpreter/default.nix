{ pkgs, ... }:

let
  open-interpreter = pkgs.writeShellApplication {
    name = "interpreter";

    runtimeInputs = [ pkgs.open-interpreter ];
    text = ''
      interpreter --api-key "$(cat ~/.openai/api.key)"
    '';
  };
in
{
  home.packages = [
    open-interpreter
  ];
}
