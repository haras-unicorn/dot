{ pkgs, ... }:

{
  services.locate.enable = true;
  services.locate.package = pkgs.plocate;
  services.locate.interval = "hourly";

  # TODO: add more
  services.locate.pruneNames = [
    ".bzr"
    ".cache"
    ".git"
    ".hg"
    ".svn"
    "node_modules"
    "target"
    ".direnv"
  ];
}
