{ self, ... }:

{
  imports = [
    "${self}/src/module/home/qtile"
    "${self}/src/module/home/dunst"
    "${self}/src/module/home/rofi"
    "${self}/src/module/home/redshift"
    "${self}/src/module/home/random-background"
    "${self}/src/module/home/obs-studio"
    "${self}/src/module/home/brightnessctl"
    "${self}/src/module/home/playerctl"
  ];

  programs.feh.enable = true;
  services.flameshot.enable = true;
  services.betterlockscreen.enable = true;
}
