{
  self.homeModules.tesseract.value =
    { pkgs, ... }:
    let
      package = pkgs.tesseract;
    in
    {
      home.packages = [
        package
      ];
    };
}
