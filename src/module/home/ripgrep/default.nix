{ pkgs, ... }:

# TODO: colors (see man rg)

{
  home.shared = {
    shell.aliases = {
      grep = "${pkgs.ripgrep}/bin/rg";
    };

    programs.ripgrep.enable = true;
    programs.ripgrep.arguments = [
      "--max-columns=100"
      "--max-columns-preview"
      "--smart-case"
    ];
  };
}
