{
  machines.homeModules.umu-launcher =
    { pkgs, lib, ... }:
    lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
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
