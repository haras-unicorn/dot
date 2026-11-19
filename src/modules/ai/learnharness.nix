{ inputs, ... }:

{
  self.homeModules.learnharness.value =
    {
      config,
      lib,
      pkgs,
      unstablePkgs,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      # NOTE: the haraspkgs helpers are not in pkgs.harasPackages of a
      # downstream flake yet, so this extends pkgs with them like stolon does
      harasPackages = (pkgs.extend inputs.haraspkgs.overlays.default).harasPackages;

      learnharness = harasPackages.learnharness;
    in
    lib.mkIf hardware.browser {
      home.packages = [ learnharness ];

      xdg.desktopEntries.learnharness = {
        name = "LearnHarness";
        exec = lib.getExe learnharness;
        terminal = false;
      };
    };
}
