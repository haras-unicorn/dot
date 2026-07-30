{
  machines.homeModules.hyprpicker =
    { pkgs, ... }:
    let
      package = pkgs.hyprpicker;

      source = pkgs.writeShellApplication {
        name = "hyprpicker-source";
        runtimeInputs = [ pkgs.hyprpicker ];
        text = "hyprpicker --no-fancy";
      };
    in
    {
      dot.processing.sources.hyprpicker = {
        note = "Pick a single pixel on the screen and save its hex value";
        tags = [
          "color"
          "picker"
          "hex"
          "screen"
        ];
        output = "text/plain";
        package = source;
      };

      home.packages = [
        package
      ];
    };
}
