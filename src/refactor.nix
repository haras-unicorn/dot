{ pkgs, config, ... }:

# FIXME: tree-sitter not finding grammars

let
  refactor = pkgs.writeShellApplication {
    name = "refactor";
    runtimeInputs = [ pkgs.git ];
    text = ''
      USAGE="Usage: refactor <command> [name]
      Commands:
        create <name>  - Create a new refactoring script
        apply <name>   - Apply the specified refactoring script
        help           - Show this help message
      "

      if [ "$#" -lt 1 ]; then
        echo "Error: No command provided."
        echo "$USAGE"
        exit 1
      fi

      COMMAND=''${1:-}
      NAME=''${2:-}

      REPO_PATH="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
      if [ -z "$REPO_PATH" ]; then
        echo "Error: Not inside a git repository."
        exit 1
      fi

      REPO_NAME="$(basename "$REPO_PATH" || echo "unknown")"
      REF_DIR="${config.xdg.dataHome}/refactor/$REPO_NAME"
      SCRIPT_PATH="$REF_DIR/$NAME"

      case "$COMMAND" in
        create)
          if [ -z "$NAME" ]; then
            echo "Error: No script name provided."
            echo "$USAGE"
            exit 1
          fi

          if [ ! -f "$SCRIPT_PATH" ]; then
            mkdir -p "$REF_DIR"
            touch "$SCRIPT_PATH"
            chmod +x "$SCRIPT_PATH"

            {
              echo "#!/usr/bin/env nu"
              echo ""
              echo "def main [repo: string] {"
              echo "}"
            } > "$SCRIPT_PATH"

            exit 1
          fi

          "''${EDITOR}" "$SCRIPT_PATH"
          ;;
        apply)
          if [ -z "$NAME" ]; then
            echo "Error: No script name provided."
            echo "$USAGE"
            exit 1
          fi

          if [ ! -f "$SCRIPT_PATH" ]; then
            echo "Error: Script '$NAME' does not exist."
            exit 1
          fi

          echo "Applying refactor script: $SCRIPT_PATH"
          "$SCRIPT_PATH" "$REPO_PATH"
          ;;
        help)
          echo "$USAGE"
          ;;
        *)
          echo "Error: Unknown command '$COMMAND'."
          echo "$USAGE"
          exit 1
          ;;
      esac
    '';
  };
in
{
  integrate.homeManagerModule.homeManagerModule = {
    xdg.configFile."tree-sitter/config.json".text = builtins.toJSON {
      "parser-directories" = [
        (pkgs.tree-sitter.withPlugins (p: builtins.attrValues p))
      ];
    };

    home.packages = [
      refactor
      pkgs.rnr
      pkgs.fastmod
      pkgs.ast-grep
      pkgs.tree-sitter
      pkgs.mo
      (pkgs.rustPlatform.buildRustPackage (
        let
          version = "1.3.0";
        in
        {
          inherit version;
          pname = "stdrename";
          src = pkgs.fetchFromGitHub {
            owner = "Gadiguibou";
            repo = "stdrename";
            rev = "v${version}";
            sha256 = "sha256-DdxHNwL108t2C5LN/sMxq5VqyYtDrKXgJeO45ZJvHdA=";
          };
          cargoHash = "sha256-+IkD4JN4Cm7VXxRGrOl7Ju2djccHRtkvSEHGAfu9u68=";
          meta = {
            description = "Small command line utility to rename all files in a folder according to a specified naming convention (camelCase, snake_case, kebab-case, etc.).";
            homepage = "https://github.com/Gadiguibou/stdrename";
            license = pkgs.lib.licenses.gpl3;
          };
        }
      ))
    ];
  };
}
