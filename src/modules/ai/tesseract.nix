{
  machines.homeModules.tesseract =
    { pkgs, config, ... }:
    let
      package = pkgs.tesseract;

      processor = pkgs.writeShellApplication {
        name = "tesseract-processor";
        runtimeInputs = [ package ];
        text = ''
          cat | tesseract --psm 1 --oem 1 stdin stdout "$@" | sed -z 's/^[[:space:]]*//; s/[[:space:]]*$//'
        '';
      };
    in
    {
      dot.processing.nodes.tesseract-ocr = {
        note = "Recognize the characters in the image";
        tags = [
          "ocr"
          "image"
          "text"
        ];
        inputs = [ "image/png" ];
        output = "text/plain";
        package = processor;
      };

      home.packages = [
        package
      ];
    };
}
