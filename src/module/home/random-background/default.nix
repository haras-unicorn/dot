{ self, ... }:

# via xdg?

{
  services.random-background.enable = true;
  services.random-background.imageDirectory = "%h/.local/share/wallpapers";
  home.file.".local/share/wallpapers".source = "${self}/assets/wallpapers";
}
