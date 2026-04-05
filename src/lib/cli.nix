{
  lib,
  self,
  config,
  ...
}:

{
  options.dot = {
    cli = {
      makeRuntimeInputs = lib.mkOption {
        type = lib.types.listOf (lib.types.functionTo (lib.types.listOf lib.types.package));
        default = [ ];
        description = "Functions which evaluate to packages for the script";
      };

      text = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Script text";
      };
    };
  };

  config = {
    libAttrs.cli.mkCli =
      pkgs:
      {
        name ? "dot",
        runtimeInputs ? [ ],
        text ? "",
        finalRuntimeInputs ? [
          pkgs.nushell
        ]
        ++ (lib.flatten (
          builtins.map (makeRuntimeInputs: makeRuntimeInputs pkgs) config.dot.cli.makeRuntimeInputs
        ))
        ++ runtimeInputs,
        finalText ? ''
          def main [] {
            exec nu -c $"($env.FILE_PWD)/${name} --help"
          }

          ${config.dot.cli.text}

          ${text}
        '',
      }:
      self.lib.nushell.mkNushellApplication pkgs {
        inherit name;
        runtimeInputs = finalRuntimeInputs;
        text = finalText;
      };
  };
}
