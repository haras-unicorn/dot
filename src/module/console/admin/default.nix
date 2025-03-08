{ pkgs, ... }:

# TODO: please or doas

{
  integrate.nixosModule.nixosModule = {
    security.sudo.package = pkgs.sudo.override { withInsults = true; };
  };
}
