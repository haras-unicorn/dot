{ pkgs, config, lib, ... }:

let
  user = config.dot.user;

  hasNetwork = config.dot.hardware.network.enable;

  path = "/home/${user}/.secrets/deepseek-api-key";

  crush = pkgs.writeShellApplication {
    name = "crush";
    runtimeInputs = [
      pkgs.nur.repos.charmbracelet.crush
    ];
    text = ''
      # shellcheck disable=SC2155
      export DEEPSEEK_API_KEY="$(cat ${path})"
      crush "$@"
    '';
  };
in
{
  branch.homeManagerModule.homeManagerModule = lib.mkIf hasNetwork {
    home.packages = [
      crush
    ];

    xdg.configFile."crush/crush.json".source = ./crush.json;
  };

  branch.nixosModule.nixosModule = {
    sops.secrets."deepseek-api-key" = {
      inherit path;
      owner = user;
      group = "users";
      mode = "0400";
    };

    rumor.sops = [
      "deepseek-api-key"
    ];
    rumor.specification.imports = [
      {
        importer = "vault-file";
        arguments = {
          path = "kv/dot/shared";
          file = "deepseek-api-key";
          allow_fail = false;
        };
      }
    ];
  };
}
