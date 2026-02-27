# TODO: please or doas

{
  flake.nixosModules.programs-sudo =
    { pkgs, ... }:
    {
      security.sudo.package = pkgs.sudo.override { withInsults = true; };
    };
}
