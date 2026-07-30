{
  machines.homeModules.nom =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      package = pkgs.nix-output-monitor;

      exe = lib.getExe package;
    in
    {
      home.packages = [
        package
      ];

      dot.programs.shell.aliases = {
        "nix build" = "${exe} build";
        "nix shell" = "${exe} shell";
        "nix develop" = "${exe} develop";

        "nix-build" = lib.getExe' package "nom-build";
        "nix-shell" = lib.getExe' package "nom-shell";
      };
    };
}
