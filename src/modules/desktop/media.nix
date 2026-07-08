{ selfLib, ... }:

{
  machines.homeModules.media =
    {
      pkgs,
      lib,
      config,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf hardware.browser {
      dot.mime.apps = [
        {
          package = pkgs.transmission_4-gtk;
          types = selfLib.mime.torrent;
        }
        {
          package = pkgs.libreoffice-fresh;
          types = selfLib.mime.office;
        }
        {
          package = pkgs.loupe;
          types = selfLib.mime.image;
        }
        {
          package = pkgs.kdePackages.okular;
          types = selfLib.mime.pdf;
        }
        {
          package = pkgs.vlc;
          types = selfLib.mime.audio ++ selfLib.mime.video;
        }
        {
          package = pkgs.xarchiver;
          types = selfLib.mime.archive;
        }
      ];
    };
}
