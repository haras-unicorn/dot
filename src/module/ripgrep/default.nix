{ pkgs, ... }:

# TODO: colors (see man rg)

{
  shared = {
    dot = {
      shell.aliases = {
        grep = "${pkgs.ripgrep}/bin/rg";
      };
    };
  };

  home.shared = {
    programs.ripgrep.enable = true;
    programs.ripgrep.arguments = [
      "--max-columns=100"
      "--max-columns-preview"
      "--smart-case"
    ];
  };
}
