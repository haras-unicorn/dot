{
  pkgs,
  config,
  lib,
  ...
}:

let
  user = config.dot.host.user;

  hasNetwork = config.dot.hardware.network.enable;

  deepseekPath = "/home/${user}/.secrets/deepseek-api-key";
  openaiPath = "/home/${user}/.secrets/openai-api-key";
  openrouterPath = "/home/${user}/.secrets/openrouter-api-key";

  crush = pkgs.writeShellApplication {
    name = "crush";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.nur.repos.charmbracelet.crush
    ];
    text = ''
      # shellcheck disable=SC2155
      export DEEPSEEK_API_KEY="$(cat ${deepseekPath})"
      # shellcheck disable=SC2155
      export OPENAI_API_KEY="$(cat ${openaiPath})"
      # shellcheck disable=SC2155
      export OPENROUTER_API_KEY="$(cat ${openrouterPath})"
      crush "$@"
    '';
  };
in
{
  homeManagerModule = lib.mkIf hasNetwork {
    home.packages = [
      crush
    ];

    xdg.configFile."crush/crush.json".source = ./crush.json;
  };

  nixosModule = lib.mkIf hasNetwork {
    sops.secrets."deepseek-api-key" = {
      path = deepseekPath;
      owner = user;
      group = user;
      mode = "0400";
    };
    sops.secrets."openai-api-key" = {
      path = openaiPath;
      owner = user;
      group = user;
      mode = "0400";
    };
    sops.secrets."openrouter-api-key" = {
      path = openrouterPath;
      owner = user;
      group = user;
      mode = "0400";
    };

    rumor.sops = [
      "deepseek-api-key"
      "openai-api-key"
      "openrouter-api-key"
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
      {
        importer = "vault-file";
        arguments = {
          path = "kv/dot/shared";
          file = "openrouter-api-key";
          allow_fail = false;
        };
      }
    ];
  };
}
