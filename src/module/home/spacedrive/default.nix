{ config, ... }:

# TODO: https://github.com/NixOS/nixpkgs/issues/170254

{
  home.packages = [ config.nur.repos.mikaelfangel-nur.spacedrive ];
}
