{ pkgs, ... }:

{
  services.locate.enable = true;
  services.locate.package = pkgs.plocate;
  services.locate.interval = "hourly";
  services.locate.localuser = null;

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
