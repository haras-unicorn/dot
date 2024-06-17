{ pkgs, ... }:

{
  home = {
    shared = {
      home.packages = [
        (pkgs.appimageTools.wrapType2 {
          pname = "cursor";
          version = "0.1.0";

          src = pkgs.fetchurl {
            url = "https://downloader.cursor.sh/linux/appImage/x64";
            hash = "sha256-Fsy9OVP4vryLHNtcPJf0vQvCuu4NEPDTN2rgXO3Znwo=";
          };
        })
      ];
    };
  };
}

