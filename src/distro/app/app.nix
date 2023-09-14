{ self, pkgs, ... }:

{
  imports = [
    # TODO: somehow on qt and hyprland??
    # "${self}/src/module/home/cursor/cursor.nix"
    "${self}/src/module/home/gtk/gtk.nix"
    "${self}/src/module/home/qt/qt.nix"
    "${self}/src/module/home/brave/brave.nix"
    "${self}/src/module/home/spotify/spotify.nix"
    "${self}/src/module/home/kitty/kitty.nix"
    "${self}/src/module/home/syncthing/syncthing.nix"
    "${self}/src/module/home/keepassxc/keepassxc.nix"
    "${self}/src/module/home/sdui/sdui.nix"
  ];

  home.packages = with pkgs; [
    emote
    (pkgs.symlinkJoin {
      name = "ferdium";
      paths = [ pkgs.ferdium ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/ferdium --append-flags --ozone-platform-hint=auto
      '';
    })
    libreoffice-fresh
    vlc
    shotwell
    pinta
  ];

  services.udiskie.enable = true;
  services.network-manager-applet.enable = true;
}
