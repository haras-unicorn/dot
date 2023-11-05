{ pkgs, ... }:

let
  mime = { };
in
{
  home.packages = with pkgs; [
    nomacs
  ];

  xdg.mimeApps.associations.added = mime;
  xdg.mimeApps.defaultApplications = mime;
}
