{ pkgs, config, hostName, system, ... }:

let
  rebuild = pkgs.writeShellApplication {
    name = "rebuild";
    runtimeInputs = [ ];
    text = ''
      sudo nixos-rebuild switch \
        --flake "$(readlink -f "${config.xdg.dataHome}/dot")#${hostName}-${system}" \
        "$@"
    '';
  };

  rebuild-trace = pkgs.writeShellApplication {
    name = "rebuild-trace";
    runtimeInputs = [ ];
    text = ''
      sudo nixos-rebuild switch \
        --flake "$(readlink -f "${config.xdg.dataHome}/dot")#${hostName}-${system}" \
        --show-trace \
        --option eval-cache false \
        "$@"
    '';
  };
in
{
  home = {
    home.packages = [ rebuild rebuild-trace ];
  };
}
