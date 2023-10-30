{ self, ... }:

{
  services.random-background.enable = true;
  # TODO: via xdg?
  services.random-background.imageDirectory = "%h/.local/share/wallpapers";
  home.file.".local/share/wallpapers".source = "${self}/assets/wallpapers";
}
