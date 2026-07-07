{
  machines.homeModules.github-cli =
    {
      osConfig,
      pkgs,
      lib,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf hardware.editor {
      programs.gh = {
        enable = true;
      };
    };
}
