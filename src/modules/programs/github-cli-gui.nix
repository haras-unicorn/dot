{
  machines.homeModules.github-cli =
    {
      osConfig,
      config,
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
        settings = {
          git_protocol = "ssh";
          editor = lib.getExe config.dot.programs.editor.package;
        };
      };
    };
}
