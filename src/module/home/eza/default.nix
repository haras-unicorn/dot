{ pkgs, config, ... }:

{
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

  # TODO: remove when https://github.com/nix-community/home-manager/pull/4590
  home.shellAliases = {
    la = "${pkgs.eza}/bin/eza ${pkgs.lib.escapeShellArgs config.programs.eza.extraOptions}";
    tree = "${pkgs.eza}/bin/eza ${pkgs.lib.escapeShellArgs config.programs.eza.extraOptions} --tree";
  };
}
