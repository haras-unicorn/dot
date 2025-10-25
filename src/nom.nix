{ pkgs, ... }:

let
  package = pkgs.nix-output-monitor;
in
{
  branch.homeManagerModule.homeManagerModule = {
    home.packages = [
      package
    ];

    dot.shell.aliases = {
      "nix build" = "${package}/bin/nom build";
      "nix shell" = "${package}/bin/nom shell";
      "nix develop" = "${package}/bin/nom develop";

      "nix-build" = "${package}/bin/nom-build";
      "nix-shell" = "${package}/bin/nom-shell";
    };
  };
}
