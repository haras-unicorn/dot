{ pkgs, ... }:

{
  system = {
    security.pam.services.gtklock = { };
  };

  home.shared = {
    home.packages = [
      pkgs.gtklock
    ];
  };
}
