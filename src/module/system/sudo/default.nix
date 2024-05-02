{ pkgs, ... }:

# TODO: please or doas

{
  system = {
    security.sudo.package = pkgs.sudo.override { withInsults = true; };
  };
}
