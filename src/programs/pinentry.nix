{
  flake.homeModules.programs-pinentry =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hasMonitor = config.dot.hardware.monitor.enable;
    in
    {
      dot.pinentry = {
        package = if hasMonitor then pkgs.pinentry-qt else pkgs.pinentry-curses;
        bin = if hasMonitor then "pinentry-qt" else "pinentry-curses";
      };
    };
}
