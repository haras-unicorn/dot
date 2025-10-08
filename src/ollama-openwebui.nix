{
  self,
  aiPkgs,
  pkgs,
  lib,
  config,
  ...
}:

# FIXME: https://www.youtube.com/watch?v=GyWuQwEsbe8
# ^^ use open webui from pkgs

let
  hasGpu = config.nixpkgs.config.cudaSupport || config.nixpkgs.config.rocmSupport;

  chromium = self.lib.chromium.wrap pkgs pkgs.ungoogled-chromium "chromium";

  mkOllamaInstance = instanceName: rec {
    ollama = pkgs.writeShellApplication {
      name = "ollama-${instanceName}";
      runtimeInputs = [
        pkgs.ollama
        pkgs.coreutils
      ];
      text = ''
        mkdir -p "${config.xdg.dataHome}/ollama/${instanceName}"
        cd "${config.xdg.dataHome}/ollama/${instanceName}"
        export HOME="${config.xdg.dataHome}/ollama/${instanceName}"
        ollama "$@"
      '';
    };

    openWebui = pkgs.writeShellApplication {
      name = "open-webui-${instanceName}";
      runtimeInputs = [
        aiPkgs.open-webui
        pkgs.coreutils
      ];
      text = ''
        mkdir -p "${config.xdg.dataHome}/ollama/${instanceName}/ui"
        cd "${config.xdg.dataHome}/ollama/${instanceName}/ui"
        export STATIC_DIR="${config.xdg.dataHome}/ollama/${instanceName}/ui"
        export DATA_DIR="${config.xdg.dataHome}/ollama/${instanceName}/ui"
        export HF_HOME="${config.xdg.dataHome}/ollama/${instanceName}/ui"
        export SENTENCE_TRANSFORMERS_HOME="${config.xdg.dataHome}/ollama/${instanceName}/ui"
        export ENV=prod
        open-webui "$@"
      '';
    };

    desktopApp = self.lib.serverClientApp pkgs {
      name = "ollama-${instanceName}-app";
      display = "Ollama OpenWebUI (${instanceName})";
      runtimeInputs = [
        ollama
        openWebui
        chromium
      ];
      servers = [
        "env OLLAMA_HOST=http://127.0.0.1:$port0 ollama-${instanceName} serve"
        "env OLLAMA_BASE_URL=http://127.0.0.1:$port0 WEBUI_AUTH=False open-webui-${instanceName} serve --host 127.0.0.1 --port $port1"
      ];
      waits = [
        ''curl -s "http://localhost:$port0"''
        ''curl -s "http://localhost:$port1"''
      ];
      client = ''
        chromium \
          "--user-data-dir=${config.xdg.dataHome}/ollama/${instanceName}/session" \
          "--app=http://localhost:$port1" \
      '';
    };
  };

  instances = {
    personal = mkOllamaInstance "personal";
    alternative = mkOllamaInstance "alternative";
  };
in
{
  branch.homeManagerModule.homeManagerModule = {
    config = lib.mkIf hasGpu {
      home.packages = with instances; [
        personal.ollama
        personal.openWebui
        personal.desktopApp
        alternative.ollama
        alternative.openWebui
        alternative.desktopApp
      ];

      xdg.desktopEntries = {
        ollama-personal = {
          name = "Ollama OpenWebUI";
          exec = "${instances.personal.desktopApp}/bin/ollama-personal-app";
          terminal = false;
        };
      };
    };
  };
}
