{ ... }:

{
  system = {
    services.xserver.windowManager.qtile.enable = true;
    services.xserver.windowManager.qtile.extraPackages =
      python3Packages: with python3Packages; [
        psutil
      ];

    de.session = "none+qtile";
  };
}
