{ self, ... }:

{
  imports = [
    "${self}/src/module/home/qtile/qtile.nix"
    "${self}/src/module/home/dunst/dunst.nix"
    "${self}/src/module/home/rofi/rofi.nix"
    "${self}/src/module/home/redshift/redshift.nix"
    "${self}/src/module/home/wallpaper/wallpaper.nix"
  ];

  programs.feh.enable = true;
}
