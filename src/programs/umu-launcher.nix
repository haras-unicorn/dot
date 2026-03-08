{
  flake.homeModules.umu-launcher =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      hasMonitor = config.dot.hardware.monitor.enable;
      hasMouse = config.dot.hardware.mouse.enable;
      hasKeyboard = config.dot.hardware.keyboard.enable;
    in
    lib.mkIf
      (hasMonitor && hasMouse && hasKeyboard && (pkgs.stdenv.hostPlatform.system == "x86_64-linux"))
      {
        home.packages = [
          pkgs.umu-launcher
        ];

        programs.lutris.extraPackages = [
          pkgs.umu-launcher
        ];
        programs.lutris.protonPackages = [
          pkgs.proton-ge-bin
        ];
      };
}
