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

      wrapAppendFlags = builtins.concatStringsSep " " (builtins.map (x: "--append-flags '${x}'") args);
    in
    lib.mkIf hardware.interface {
      dot.programs.chromium = {
        inherit args;

        package = config.dot.programs.chromium.wrap pkgs.ungoogled-chromium "chromium";

        wrap =
          package: bin:
          pkgs.symlinkJoin {
            name = bin;
            paths = [ package ];
            buildInputs = [ pkgs.makeWrapper ];
            postBuild = "wrapProgram $out/bin/${bin} ${wrapAppendFlags}";
          };

        launch =
          name: address: incognito:
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
    lib.mkIf hardware.interface {
      programs.chromium.enable = true;
      programs.chromium.package = osConfig.dot.programs.chromium.package;
      programs.chromium.dictionaries = with pkgs.hunspellDictsChromium; [
        en_US
      ];
    };
}
