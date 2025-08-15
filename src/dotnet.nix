{
  pkgs,
  ...
}:

let
  sdk = pkgs.dotnetCorePackages.combinePackages (
    with pkgs.dotnetCorePackages;
    [
      # vscode extension
      sdk_9_0_3xx
      # latest LTS
      sdk_8_0_3xx
    ]
  );

  root = "${sdk}/share/dotnet";
in
{
  branch.homeManagerModule.homeManagerModule = {
    home.packages = [
      sdk
    ];

    home.sessionVariables = {
      DOTNET_ROOT = root;
    };
  };
}
