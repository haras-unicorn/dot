{ pkgs, config, ... }:

{
  home.packages = with pkgs; [
    spotify-tui
  ];

  services.spotifyd.enable = true;
  services.spotifyd.package = pkgs.spotifyd.override { withKeyring = true; };
  # security add-generic-password -s spotifyd -D rust-keyring -a <your username> -w
  services.spotifyd.settings = {
    global = {
      username = "ftsedf157kfova8yuzoq1dfax";
      # TODO: check if has keyring?
      use_keyring = true;
      use_mpris = true;
      dbus_type = "session";
      backend = "pulseaudio";
      bitrate = 320;
      cache_path = "${config.xdg.cacheHome}/spotifyd";
      volume_normalisation = true;
      device_type = "computer";
      # TODO: from meta?
      device_name = "desktop-haras";
      zeroconf_port = 8888;
    };
  };
}
