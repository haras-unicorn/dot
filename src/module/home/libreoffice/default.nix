{ pkgs, ... }:

let
  mime = { };
in
{
  home.packages = with pkgs; [
    libreoffice-fresh
  ];

  xdg.mimeApps.associations.added = mime;
  xdg.mimeApps.defaultApplications = mime;
}
