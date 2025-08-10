{ pkgs, config, lib, ... }:

let
  user = config.dot.user;

  hasNetwork = config.dot.hardware.network.enable;

  deepseekPath = "/home/${user}/.secrets/deepseek-api-key";
  openaiPath = "/home/${user}/.secrets/openai-api-key";

  crush = pkgs.writeShellApplication {
    name = "crush";
    runtimeInputs = [
      pkgs.nur.repos.charmbracelet.crush
    ];
    text = ''
      # shellcheck disable=SC2155
      export DEEPSEEK_API_KEY="$(cat ${deepseekPath})"
      # shellcheck disable=SC2155
      export OPENAI_API_KEY="$(cat ${openaiPath})"
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

  branch.nixosModule.nixosModule = lib.mkIf hasNetwork {
    sops.secrets."deepseek-api-key" = {
      path = deepseekPath;
      owner = user;
      group = "users";
      mode = "0400";
    };
    sops.secrets."openai-api-key" = {
      path = openaiPath;
      owner = user;
      group = "users";
      mode = "0400";
    };

    rumor.sops = [
      "deepseek-api-key"
      "openai-api-key"
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
      {
        importer = "vault-file";
        arguments = {
          path = "kv/dot/shared";
          file = "openai-api-key";
          allow_fail = false;
        };
      }
    ];
  };
}
