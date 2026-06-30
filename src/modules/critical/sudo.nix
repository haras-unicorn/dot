# TODO: please or doas

{
  machines.nixosModules.sudo =
    { pkgs, ... }:
    {
      security.sudo.package = pkgs.sudo.override { withInsults = true; };
    };
}
