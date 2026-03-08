{
  flake.homeModules.programs-wine =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      # TODO: when support better
      # hasWayland = config.dot.hardware.graphics.wayland;
      # wine32Package =
      #   if hasWayland then pkgs.wineWowPackages.waylandFull else pkgs.wineWowPackages.stableFull;
      # wine64Package =
      #   if hasWayland then pkgs.wineWow64Packages.waylandFull else pkgs.wineWow64Packages.stableFull;
      wine32Package = pkgs.wineWowPackages.stableFull;
      wine64Package = pkgs.wineWow64Packages.stableFull;
      winetricksPackage = pkgs.winetricks;

      prefixes = "${config.home.homeDirectory}/.local/share/wine/prefixes";

      mkWrappers =
        { is32Bit }:
        {
          winecfgWrapper = pkgs.writeShellApplication {
            name = if is32Bit then "winecfg-32-in" else "winecfg-in";
            runtimeInputs = [
              (if is32Bit then wine32Package else wine64Package)
            ];
            text = ''
              if [ -z "$1" ]; then
                echo "Usage: $0 <prefix-name>"
                exit 1
              fi
              export WINEPREFIX="${prefixes}/$1"
              export WINEARCH="${if is32Bit then "win32" else "win64"}"
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
            name = if is32Bit then "wine-32-in" else "wine-in";
            runtimeInputs = [
              (if is32Bit then wine32Package else wine64Package)
            ];
            text = ''
              if [ -z "$1" ]; then
                echo "Usage: $0 <prefix-name> [wine-args...]"
                exit 1
              fi
              export WINEPREFIX="${prefixes}/$1"
              export WINEARCH="${if is32Bit then "win32" else "win64"}"
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
            name = if is32Bit then "winetricks-32-in" else "winetricks-in";
            runtimeInputs = [
              (if is32Bit then wine32Package else wine64Package)
              winetricksPackage
            ];
            text = ''
              if [ -z "$1" ]; then
                echo "Usage: $0 <prefix-name> [winetricks-args...]"
                exit 1
              fi
              export WINEPREFIX="${prefixes}/$1"
              export WINEARCH="${if is32Bit then "win32" else "win64"}"
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
        };
    in
    lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
      programs.lutris.winePackages = [
        wine32Package
        wine64Package
      ];
      programs.lutris.extraPackages = [
        winetricksPackage
      ];

      home.packages = [
        wine64Package
        winetricksPackage
      ]
      ++ (builtins.attrValues (mkWrappers {
        is32Bit = true;
      }))
      ++ (builtins.attrValues (mkWrappers {
        is32Bit = false;
      }));
    };
}
