{
  self,
  nix-comfyui,
  pkgs,
  lib,
  config,
  ...
}:

let
  hasGpu = config.nixpkgs.config.cudaSupport || config.nixpkgs.config.rocmSupport;

  chromium = config.dot.chromium.wrap pkgs pkgs.ungoogled-chromium "chromium";

  packageName =
    if config.nixpkgs.config.cudaSupport then
      "cuda-comfyui-with-extensions"
    else if config.nixpkgs.config.rocmSupport then
      "rocm-comfyui-with-extensions"
    else
      null;

  comfyuiPackage = nix-comfyui.packages.${pkgs.system}.${packageName};

  mkComfyuiInstance = instanceName: rec {
    comfyui = pkgs.writeShellApplication {
      name = "comfyui-${instanceName}";
      runtimeInputs = [
        comfyuiPackage
        pkgs.coreutils
      ];
      text = ''
        mkdir -p "${config.xdg.dataHome}/comfyui/${instanceName}"
        cd "${config.xdg.dataHome}/comfyui/${instanceName}"
        comfyui "$@"
      '';
    };

    desktopApp = self.lib.serverClientApp pkgs {
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
  branch.homeManagerModule.homeManagerModule = {
    config = lib.mkIf hasGpu {
      home.packages = with instances; [
        personal.comfyui
        personal.desktopApp
        alternative.comfyui
        alternative.desktopApp
      ];

      xdg.desktopEntries = {
        comfyui-personal = {
          name = "ComfyUI";
          exec = "${instances.personal.desktopApp}/bin/comfyui-personal-app";
          terminal = false;
        };
      };
    };
  };
}
