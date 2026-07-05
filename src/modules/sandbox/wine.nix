{
  machines.homeModules.wine =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      wine64Package = pkgs.wineWow64Packages.stableFull;
      winetricksPackage = pkgs.winetricks;

      prefixes = "${config.home.homeDirectory}/.local/share/wine/prefixes";

      winecfgWrapper = pkgs.writeShellApplication {
        name = "winecfg-in";
        runtimeInputs = [
          wine64Package
        ];
        text = ''
          if [ -z "$1" ]; then
            echo "Usage: $0 <prefix-name>"
            exit 1
          fi
          export WINEPREFIX="${prefixes}/$1"
          export WINEARCH="win64"
          if [ ! -d "$WINEPREFIX" ]; then
            mkdir -p "$WINEPREFIX"
            echo "Creating new prefix: $WINEPREFIX"
          else
            echo "Running in prefix: $WINEPREFIX"
          fi
          winecfg
        '';
      };

      wineWrapper = pkgs.writeShellApplication {
        name = "wine-in";
        runtimeInputs = [
          wine64Package
        ];
        text = ''
          if [ -z "$1" ]; then
            echo "Usage: $0 <prefix-name> [wine-args...]"
            exit 1
          fi
          export WINEPREFIX="${prefixes}/$1"
          export WINEARCH="win64"
          if [ ! -d "$WINEPREFIX" ]; then
            echo "Creating new prefix: $WINEPREFIX"
            mkdir -p "$WINEPREFIX"
            winecfg
          else
            echo "Running in prefix: $WINEPREFIX"
          fi
          shift
          wine "$@"
        '';
      };

      winetricksWrapper = pkgs.writeShellApplication {
        name = "winetricks-in";
        runtimeInputs = [
          wine64Package
          winetricksPackage
        ];
        text = ''
          if [ -z "$1" ]; then
            echo "Usage: $0 <prefix-name> [winetricks-args...]"
            exit 1
          fi
          export WINEPREFIX="${prefixes}/$1"
          export WINEARCH="win64"
          if [ ! -d "$WINEPREFIX" ]; then
            echo "Creating new prefix: $WINEPREFIX"
            mkdir -p "$WINEPREFIX"
            winecfg
          else
            echo "Running in prefix: $WINEPREFIX"
          fi
          shift
          winetricks "$@"
        '';
      };
    in
    lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
      programs.lutris.winePackages = [
        wine64Package
      ];
      programs.lutris.extraPackages = [
        winetricksPackage
      ];

      home.packages = [
        wine64Package
        winetricksPackage
        winecfgWrapper
        wineWrapper
        winetricksWrapper
      ];
    };
}
