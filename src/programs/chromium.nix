{
  config,
  pkgs,
  lib,
  ...
}:

let
  hasMonitor = config.dot.hardware.monitor.enable;
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

  wrap =
    pkgs: package: bin:
    pkgs.symlinkJoin {
      name = bin;
      paths = [ package ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''wrapProgram $out/bin/${bin} ${flags}'';
    };

  args = builtins.concatStringsSep " " rawArgs;

  options.dot = {
    chromium.wrap = lib.mkOption {
      type = lib.types.raw;
      default = wrap;
    };

    chromium.args = lib.mkOption {
      type = lib.types.raw;
      default = args;
    };
  };

  package = config.dot.chromium.wrap pkgs pkgs.ungoogled-chromium "chromium";
in
{
  nixosModule = {
    inherit options;
  };

  homeManagerModule = {
    inherit options;

    config = lib.mkIf hasMonitor {
      programs.chromium.enable = true;
      programs.chromium.package = package;
      programs.chromium.dictionaries = with pkgs.hunspellDictsChromium; [
        en_US
      ];
    };
  };
}
