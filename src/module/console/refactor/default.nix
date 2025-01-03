{ pkgs, ... }:

{
  home = {
    home.packages = [
      pkgs.rnr
      pkgs.fastmod
      (pkgs.rustPlatform.buildRustPackage (
        let
          version = "1.3.0";
        in
        {
          inherit version;
          pname = "stdrename";
          src = pkgs.fetchFromGitHub {
            owner = "Gadiguibou";
            repo = "stdrename";
            rev = "v${version}";
            sha256 = "sha256-DdxHNwL108t2C5LN/sMxq5VqyYtDrKXgJeO45ZJvHdA=";
          };
          cargoHash = "sha256-+IkD4JN4Cm7VXxRGrOl7Ju2djccHRtkvSEHGAfu9u68=";
          meta = {
            description = "Small command line utility to rename all files in a folder according to a specified naming convention (camelCase, snake_case, kebab-case, etc.).";
            homepage = "https://github.com/Gadiguibou/stdrename";
            license = pkgs.lib.licenses.gpl3;
          };
        }
      ))
    ];
  };
}
