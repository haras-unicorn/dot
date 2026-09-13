# TODO: please or doas

{
  self.nixosModules.sudo.value =
    { pkgs, ... }:
    {
      security.sudo.package = pkgs.sudo.override { withInsults = true; };
    };
}
