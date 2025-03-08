{ pkgs, config, ... }:

# TODO: colors

{
  integrate.homeManagerModule.homeManagerModule = {
    shell.aliases = {
      grep = "${pkgs.ripgrep}/bin/rg";
      la = "${pkgs.eza}/bin/eza ${pkgs.lib.escapeShellArgs config.programs.eza.extraOptions}";
      tree = "${pkgs.eza}/bin/eza ${pkgs.lib.escapeShellArgs config.programs.eza.extraOptions} --tree";
    };

    home.packages = [ pkgs.fd ];

    programs.ripgrep.enable = true;
    programs.ripgrep.arguments = [
      "--max-columns=100"
      "--max-columns-preview"
      "--smart-case"
    ];

    programs.eza.enable = true;
    programs.eza.extraOptions = [
      "--all"
      "--long"
      "--color=always"
      "--group-directories-first"
      "--icons"
      "--group"
      "--header"
      "--icons"
      "--git"
    ];
  };
}
