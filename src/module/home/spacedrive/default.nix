{ pkgs, config, ... }:

# TODO: use when more usable and stable

# NOTE: https://github.com/NixOS/nixpkgs/issues/170254
# configure and all when better

# NOTE: to remove:
# - documents/.spacedrive
# - .local/share/spacedrive
# - .cache/spacedrive

let
  desktopEntry = pkgs.writeText "spacedrive.desktop" ''
    [Desktop Entry]
    Categories=Application;Filesystem
    Exec=${config.nur.repos.mikaelfangel-nur.spacedrive}/bin/spacedrive %U
    GenericName=Files
    Name=Spacedrive
    Terminal=false
    Type=Application
    Version=1.4  
    MimeType=inode/directory
  '';
  mime = {
    # NOTE: like this because xdg has a problem with /nix/store hashes in filenames?
    "inode/directory" = "${config.xdg.dataHome}/applications/spacedrive.desktop";
  };
in
{
  home.packages = [ config.nur.repos.mikaelfangel-nur.spacedrive ];

  xdg.dataFile."applications/spacedrive.desktop".source = desktopEntry;
  xdg.mimeApps.associations.added = mime;
  xdg.mimeApps.defaultApplications = mime;
}