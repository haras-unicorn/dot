{ appimageTools, fetchurl }:
let
  pname = "cursor";
  version = "0.1.0";

  src = fetchurl {
    url = "https://downloader.cursor.sh/linux/appImage/x64";
    hash = "";
  };
in
{
  home = {
    shared = {
      home.packages = [
        (appimageTools.wrapType2 {
          inherit pname version src;
        })
      ];
    };
  };
}

