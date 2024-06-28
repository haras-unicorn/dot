{ pkgs, ... }:

{
  home = {
    shared = {
      home.packages = [
        (pkgs.rustPlatform.buildRustPackage rec {
          pname = "stdrename";
          version = "1.3.0";
          src = pkgs.fetchFromGitHub {
            owner = "Gadiguibou";
            repo = "stdrename";
            rev = "v${version}";
            sha256 = "sha256-DdxHNwL108t2C5LN/sMxq5VqyYtDrKXgJeO45ZJvHdA=";
          };
          cargoHash = "";
          meta = {
            description = "Small command line utility to rename all files in a folder according to a specified naming convention (camelCase, snake_case, kebab-case, etc.).";
            homepage = "https://github.com/Gadiguibou/stdrename";
            license = pkgs.lib.licenses.gpl3;
          };
        })
      ];
    };
  };
}
