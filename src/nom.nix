{ pkgs, ... }:

{
  branch.homeManagerModule.homeManagerModule = {
    home.packages = [
      pkgs.nix-output-monitor
    ];

    dot.shell.aliases = {
      "nix build" = "nom build";
      "nix shell" = "nom shell";
      "nix develop" = "nom develop";

      "nix-build" = "nom-build";
      "nix-shell" = "nom-shell";
    };
  };
}
