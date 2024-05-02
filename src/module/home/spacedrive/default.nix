{ pkgs, ... }:

# NOTE: to remove:
# - documents/.spacedrive
# - .local/share/spacedrive
# - .cache/spacedrive

let
  mime = {
    "inode/directory" = "${pkgs.spacedrive}/share/applications/spacedrive.desktop";
  };
in
{
  home.shared = {
    home.packages = with pkgs; [ spacedrive ];

    xdg.mimeApps.associations.added = mime;
    xdg.mimeApps.defaultApplications = mime;
  };
}
