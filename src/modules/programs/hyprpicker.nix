{
  self.homeModules.hyprpicker.value =
    { pkgs, ... }:
    let
      package = pkgs.hyprpicker;
    in
    {
      home.packages = [
        package
      ];
    };
}
