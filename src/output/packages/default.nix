{ flake-utils
, nixpkgs
, ...
}:

builtins.foldl'
  (apps: system: apps // {
    "${system}" = {
      rzls =
        with nixpkgs.legacyPackages.${system};
        buildDotnetModule rec {
          pname = "rzls";
          version = "3.1.30";

          src = fetchFromGitHub {
            owner = "dotnet";
            repo = "razor";
            rev = "v${version}";
            sha256 = "sha256-YX5LmiIzG2Xeno/Ys91cmrf41uK7CcV4HK2TnYEk1A8=";
          };

          nugetDeps = [ ];

          projectFile = "src/Razor/src/rzls/rzls.csproj";

          meta = {
            homepage = "https://asp.net";
            description = "Compiler and tooling experience for Razor ASP.NET Core apps in Visual Studio, Visual Studio for Mac, and VS Code.";
            license = lib.licenses.mit;
          };
        };
    };
  })
  ({ })
  flake-utils.lib.defaultSystems
