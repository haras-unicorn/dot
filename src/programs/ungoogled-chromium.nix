let
  common =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      hasGpu = config.dot.hardware.graphics.enable;
      hasWayland = config.dot.hardware.graphics.wayland;

      rawArgs =
        [ ]
        ++ lib.optionals hasWayland [
          "--enable-features=UseOzonePlatform,WaylandWindowDecorations,WebRTCPipeWireCapturer"
          "--ozone-platform=wayland"
        ]
        ++ lib.optionals hasGpu [
          "--enable-gpu-rasterization"
          "--enable-zero-copy"
        ]
        ++ lib.optionals (!hasWayland) [
          "--use-gl=egl"
        ];

      flags = builtins.concatStringsSep " " (builtins.map (x: "--append-flags '${x}'") rawArgs);
    in
    {
      dot.chromium = {
        package = config.dot.chromium.wrap pkgs.ungoogled-chromium "chromium";

        wrap =
          package: bin:
          pkgs.symlinkJoin {
            name = bin;
            paths = [ package ];
            buildInputs = [ pkgs.makeWrapper ];
            postBuild = ''wrapProgram $out/bin/${bin} ${flags}'';
          };

        args = builtins.concatStringsSep " " rawArgs;
      };
    };
in
{
  flake.nixosModules.programs-chromium = {
    imports = [ common ];
  };

  flake.homeModules.programs-chromium =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [ common ];

      config = lib.mkIf config.dot.hardware.monitor.enable {
        programs.chromium.enable = true;
        programs.chromium.package = config.dot.chromium.package;
        programs.chromium.dictionaries = with pkgs.hunspellDictsChromium; [
          en_US
        ];
      };
    };
}
