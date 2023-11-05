{ pkgs, config, ... }:

# FIXME: check if has keyring?

{
  home.packages = with pkgs; [
    spotify-tui
    spotify
  ];

  services.spotifyd.enable = true;
  services.spotifyd.package = pkgs.spotifyd.override {
    withKeyring = true;
    withMpris = true;
  };
  services.spotifyd.settings.global = {
    username = "ftsedf157kfova8yuzoq1dfax";
    # secret-tool store --label=spotifyd application rust-keyring service spotifyd username ftsedf157kfova8yuzoq1dfax
    use_keyring = true;
    use_mpris = true;
    dbus_type = "session";
    backend = "pulseaudio";
    bitrate = 320;
    cache_path = "${config.xdg.cacheHome}/spotifyd";
    volume_normalisation = true;
    device_type = "computer";
    zeroconf_port = 8888;
  };
}
