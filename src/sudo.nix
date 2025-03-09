{ pkgs, ... }:

# TODO: please or doas

{
  branch.nixosModule.nixosModule = {
    security.sudo.package = pkgs.sudo.override { withInsults = true; };
  };
}
