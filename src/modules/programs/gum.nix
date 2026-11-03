{
  self.homeModules.gum.value =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      package = pkgs.gum;
    in
    lib.mkIf hardware.editor {
      home.packages = [
        package
      ];
    };
}
