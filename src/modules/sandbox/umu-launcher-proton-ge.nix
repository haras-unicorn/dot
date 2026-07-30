{
  machines.nixosModules.umu-launcher =
    { pkgs, lib, ... }:
    lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
      programs.steam.extraCompatPackages = [
        pkgs.proton-ge-bin
      ];
    };

  machines.homeModules.umu-launcher =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      umu = pkgs.writeShellApplication {
        name = "umu";
        runtimeInputs = [
          pkgs.umu-launcher
        ];
        runtimeEnv = {
          SDL_VIDEODRIVER = "windows";
          PROTONPATH = lib.getOutput "steamcompattool" pkgs.proton-ge-bin;
        };
        text = ''
          GAMEID="$1"
          export GAMEID
          WINEPREFIX="${config.xdg.dataHome}/$GAMEID"
          export WINEPREFIX
          shift
          umu-run "$@"
        '';
      };
    in
    lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
      home.packages = [
        umu
      ];

      programs.lutris.extraPackages = [
        pkgs.umu-launcher
      ];
      programs.lutris.protonPackages = [
        pkgs.proton-ge-bin
      ];
    };
}
