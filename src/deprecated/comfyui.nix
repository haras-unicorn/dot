{ inputs, selfLib, ... }:

{
  self.lib.deprecated.homeModules.comfyui =
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

      package = if config.nixpkgs.config.cudaSupport then pkgs.comfy-ui-cuda else pkgs.comfy-ui;

      mkComfyuiInstance = instanceName: rec {
        comfyui = pkgs.writeShellApplication {
          name = "comfyui-${instanceName}";
          runtimeInputs = [
            package
          ];
          text = ''
            mkdir -p "${config.xdg.dataHome}/comfyui/${instanceName}"
            cd "${config.xdg.dataHome}/comfyui/${instanceName}"
            comfyui --base-directory "${config.xdg.dataHome}/comfyui/${instanceName}" "$@"
          '';
        };

        desktopApp = selfLib.serverClientApp.make pkgs {
          name = "comfyui-${instanceName}-app";
          display = "ComfyUI (${instanceName})";
          runtimeInputs = [
            comfyui
            chromium
          ];
          servers = [
            "comfyui-${instanceName} --preview-method taesd --port $port0"
          ];
          waits = [
            ''curl -s "http://localhost:$port0"''
          ];
          client = ''
            chromium \
              "--user-data-dir=${config.xdg.dataHome}/comfyui/${instanceName}/session" \
              "--app=http://localhost:$port0" \
          '';
        };
      };

      instances = {
        personal = mkComfyuiInstance "personal";
        alternative = mkComfyuiInstance "alternative";
      };
    in
    {
      config = lib.mkIf cuda {
        nixpkgs.overlays = [
          inputs.comfyui-nix.overlays.default
          (final: prev: {
            comfyui-manager = prev.comfyui-manager.overridePythonAttrs {
              dontCheckRuntimeDeps = true;
            };
          })
        ];

        home.packages = with instances; [
          personal.comfyui
          personal.desktopApp
          alternative.comfyui
          alternative.desktopApp
        ];

        xdg.desktopEntries = {
          comfyui-personal = {
            name = "ComfyUI";
            exec = lib.getExe instances.personal.desktopApp;
            terminal = false;
          };
        };
      };
    };
}
