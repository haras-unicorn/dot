{ selfLib, ... }:

{
  self.lib.deprecated.nixosModules.ollama-openwebui =
    { lib, config, ... }:
    let
      cuda = config.nixpkgs.config.cudaSupport;
    in
    lib.mkIf cuda {
      dot.nixpkgs.allowUnfreePredicates = [
        (
          package:
          let
            name = lib.getName package;
          in
          name == "open-webui"
        )
      ];
    };

  self.lib.deprecated.homeModules.ollama-openwebui =
    {
      pkgs,
      lib,
      config,
      osConfig,
      ...
    }:
    let
      cuda = config.nixpkgs.config.cudaSupport;

      chromium = osConfig.dot.programs.chromium.package;

      ollamaPackage = pkgs.ollama;
      openWebuiPackage = pkgs.open-webui;

      mkOllamaInstance = instanceName: rec {
        ollama = pkgs.writeShellApplication {
          name = "ollama-${instanceName}";
          runtimeInputs = [
            ollamaPackage
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
            openWebuiPackage
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

        desktopApp = selfLib.serverClientApp.make pkgs {
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
      config = lib.mkIf cuda {
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
            exec = lib.getExe instances.personal.desktopApp;
            terminal = false;
          };
        };
      };
    };
}
