{ self, selfLib, ... }:

{
  perSystem =
    { system, pkgs, ... }:
    {
      checks.default =
        pkgs.runCommand "checks-default"
          {
            src = self;
            nativeBuildInputs = selfLib.dev.makePackages pkgs;
          }
          ''
            cd "$src"
            dev lint
            touch "$out"
          '';
    };
}
