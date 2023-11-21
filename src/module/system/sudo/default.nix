{ pkgs, ... }:

# TODO: please or doas

{
  security.sudo.package = pkgs.sudo.override { withInsults = true; };
}
