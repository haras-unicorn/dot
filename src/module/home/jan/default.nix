{ pkgs, ... }:

let
  jan = pkgs.appimageTools.wrapType2 {
    name = "jan";
    src = pkgs.fetchurl {
      url = "https://github.com/janhq/jan/releases/download/v0.4.7/jan-linux-x86_64-0.4.7.AppImage";
      sha256 = "sha256-Mn7rIBEf46JbNof8h3z66TGdGKnb0FGMJc46JncA0KM=";
    };
    extraPkgs = pkgs: [ ];
  };
in
{
  home.packages = [ jan ];
}

