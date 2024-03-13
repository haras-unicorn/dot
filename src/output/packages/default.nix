{ flake-utils
, nixpkgs
, ...
}:

let
  configs = flake-utils.lib.defaultSystems;

  rzls = system:
    with nixpkgs.legacyPackages.${system};
    buildDotnetModule rec {
      pname = "rzls";
      version = "17.0.4";

      src = fetchFromGitHub {
        owner = "dotnet";
        repo = "razor";
        rev = "v${version}";
        sha256 = "";
      };

      projectFile = "src/Razor/src/rzls/rzls.csproj";

      meta = {
        homepage = "https://asp.net";
        description = "Compiler and tooling experience for Razor ASP.NET Core apps in Visual Studio, Visual Studio for Mac, and VS Code.";
        license = lib.licenses.mit;
      };
    };

in
builtins.foldl'
  (apps: system: apps // {
    "${system}" = {
      rzls = rzls system;
    };
  })
  ({ })
  configs
