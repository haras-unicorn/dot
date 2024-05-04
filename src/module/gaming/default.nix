{ pkgs
  # , self
, ...
}:

# TODO: build lutris packages from yml here with `lutris --install`
# TODO: fix clashing nofile limits

{
  system = {
    environment.systemPackages = with pkgs; [
      wineWowPackages.waylandFull
      virglrenderer
      win-virtio
      lutris
      retroarch
      cartridges
      winetricks
      protontricks

      mono # NOTE: ascension wow
      gnome.zenity # NOTE: ascension wow
      appimage-run # NOTE: ascension wow
    ];

    programs.steam.enable = true;

    users.groups.gaming = { };

    security.pam.loginLimits = [
      { domain = "@gaming"; item = "nofile"; type = "hard"; value = "524288"; }
      { domain = "@gaming"; item = "nofile"; type = "soft"; value = "524288"; }
    ];
  };
}