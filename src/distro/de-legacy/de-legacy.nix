{ self, ... }:

{
  imports = [
    "${self}/src/module/home/qtile/qtile.nix"
    "${self}/src/module/home/dunst/dunst.nix"
    "${self}/src/module/home/rofi/rofi.nix"
    "${self}/src/module/home/redshift/redshift.nix"
    "${self}/src/module/home/random-background/random-background.nix"
    "${self}/src/module/home/obs-studio/obs-studio.nix"
  ];

  programs.feh.enable = true;
  services.flameshot.enable = true;
  services.betterlockscreen.enable = true;
}
