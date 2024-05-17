{ pkgs, ... }:

let
  bend = pkgs.rustPlatform.buildRustPackage rec {
    pname = "bend";
    version = "0.2.7";

    src = pkgs.fetchFromGitHub {
      owner = "higherorderco";
      repo = pname;
      rev = version;
      hash = "sha256-yQI+p3PT1Czruc8+OZ/lZLAkBjkchkRw/OoGCYxHTDY=";
    };

    # NOTE: broken tests - something with hvm calls
    doCheck = false;

    cargoHash = "sha256-YPPBtgxqfoKnGb77m/CUYQ7+vVgL5MHhJ8I3TQ1rqK8=";

    buildInputs = [ pkgs.hvm ];

    RUSTC_BOOTSTRAP = true;

    meta = {
      description = "A massively parallel, high-level programming language";
      homepage = "https://github.com/HigherOrderCO/bend";
      license = pkgs.lib.licenses.asl20;
    };
  };
in
{
  home.shared = {
    home.packages = [
      bend
    ];
  };
}
