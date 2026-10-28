# TODO: styling via stylix
# theres a lot of environment variables...

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
