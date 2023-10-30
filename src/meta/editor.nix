{ lib, ... }:

# TODO: couple options

with lib;
{
  options.dot.editor = {
    editor.pkg = mkOption {
      type = with types; str;
      default = "vim";
      example = "helix";
    };
    editor.bin = mkOption {
      type = with types; str;
      default = "vim";
      example = "hx";
    };
    editor.module = mkOption {
      type = with types; str;
      default = "vim";
      example = "helix";
    };
  };

  config = { };
}
