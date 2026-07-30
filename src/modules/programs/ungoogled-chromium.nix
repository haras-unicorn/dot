{
  machines.nixosModules.chromium =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      hardware = config.dot.hardware;

      args = [
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
      ]
      ++ lib.optionals hardware.wayland [
        "--enable-features=UseOzonePlatform,WaylandWindowDecorations,WebRTCPipeWireCapturer"
        "--ozone-platform=wayland"
      ]
      ++ lib.optionals (!hardware.wayland) [
        "--use-gl=egl"
      ];

      wrapAppendFlags = builtins.concatStringsSep " " (
        builtins.map (arg: "--append-flags ${lib.escapeShellArg arg}") args
      );
    in
    lib.mkIf hardware.browser {
      dot.programs.chromium = {
        inherit args;

        package = config.dot.programs.chromium.wrap pkgs.ungoogled-chromium;

        wrap =
          package:
          if lib.isDerivation package then
            pkgs.symlinkJoin {
              name = lib.getName package;
              paths = [ package ];
              buildInputs = [ pkgs.makeWrapper ];
              postBuild = "wrapProgram $out/bin/${builtins.baseNameOf (lib.getExe package)} ${wrapAppendFlags}";
            }
          else
            # NOTE: super hacky but should work 99% of the time
            pkgs.symlinkJoin {
              name = builtins.baseNameOf package;
              paths = [ (builtins.dirOf (builtins.dirOf package)) ];
              buildInputs = [ pkgs.makeWrapper ];
              postBuild = "wrapProgram $out/bin/${builtins.baseNameOf package} ${wrapAppendFlags}";
            };

        launch =
          {
            name,
            address,
            incognito ? false,
            ...
          }:
          pkgs.writeShellApplication {
            name = "chromium-${name}";
            runtimeInputs = [ pkgs.ungoogled-chromium ];
            text = ''
              chromium \
                ${lib.optionalString incognito "--incognito"} \
                ${lib.escapeShellArg "--app=${address}"}
            '';
          };
      };
    };

  machines.homeModules.chromium =
    {
      osConfig,
      pkgs,
      lib,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf hardware.browser {
      programs.chromium.enable = true;
      programs.chromium.package = osConfig.dot.programs.chromium.package;
      programs.chromium.dictionaries = with pkgs.hunspellDictsChromium; [
        en_US
      ];
    };
}
