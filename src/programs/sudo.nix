{ pkgs, ... }:

# TODO: please or doas

{
  nixosModule = {
    security.sudo.package = pkgs.sudo.override { withInsults = true; };
  };
}
