{ pkgs, ... }:

# TODO: seahorse in user since it is just a gui

{
  system = {
    environment.systemPackages = with pkgs; [
      libsecret
    ];

    services.gnome.gnome-keyring.enable = true;
    programs.seahorse.enable = true;
  };
}
