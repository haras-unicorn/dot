{ pkgs, config, ... }:

# TODO: https://github.com/NixOS/nixpkgs/issues/170254

let
  desktopEntry = pkgs.writeText "spacedrive.desktop" ''
    [Desktop Entry]
    Categories=Application;Filesystem;FileManager
    Exec=${config.nur.repos.mikaelfangel-nur.spacedrive}/bin/spacedrive
    GenericName=File Manager
    Name=Spacedrive
    Terminal=false
    Type=Application
    Version=1.4  
    MimeType=inode/directory
  '';
in
{
  home.packages = [ config.nur.repos.mikaelfangel-nur.spacedrive ];

  xdg.dataFile."applications/spacedrive.desktop".source = desktopEntry;
  xdg.mimeApps.defaultApplications = {
    "inode/directory" = "${desktopEntry}";
  };
}
