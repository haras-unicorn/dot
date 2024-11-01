{
  # pkgs, 
  # config,  
  ...
}:

# TODO: use instead of waybar after
# TODO: hook up config like with waybar
# TODO: more menues
# TODO: tint-gear

# let
#   package = pkgs.eww;
#   bin = "${package}/bin/eww";
# in
{
  shared = {
    dot = {
      # desktopEnvironment.sessionStartup = [
      #   "${bin} daemon"
      # ];

      # desktopEnvironment.keybinds = [
      #   {
      #     mods = [ "super" ];
      #     key = "s";
      #     command = "${bin} open --toggle sysinfo";
      #   }
      # ];
    };
  };

  home = {
    # home.packages = [
    #   package
    # ];

    # programs.eww.enable = true;
    # programs.eww.package = package;
    # programs.eww.configDir = ./config;
  };
}
