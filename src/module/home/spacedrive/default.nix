{ config, ... }:

# TODO: https://github.com/NixOS/nixpkgs/issues/170254

{
  home.packages = [ config.nur.repos.mikaelfangel-nur.spacedrive ];

  xdg.desktopEntries = {
    spacedrive = {
      name = "Spacedrive";
      genericName = "File Manager";
      exec = "${config.nur.repos.mikaelfangel-nur.spacedrive}/bin/spacedrive";
      terminal = false;
      # TODO: check categories
      categories = [ "Application" "Filesystem" "FileManager" ];
      # TODO: check mimeTypes
      mimeType = [ ];
    };
  };
}
