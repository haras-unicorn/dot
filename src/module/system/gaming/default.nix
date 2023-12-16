{ pkgs
, ...
}:

# TODO: build lutris packages from yml here with `lutris --install`

# NOTE: https://github.com/lutris/docs/blob/master/HowToEsync.md

{
  environment.systemPackages = with pkgs; [
    wineWowPackages.stable
    virglrenderer
    win-virtio
    lutris
    retroarch
    cartridges
    winetricks
    protontricks
    mono
    gnome.zenity
  ];

  programs.steam.enable = true;

  users.groups.gaming = { };

  security.pam.loginLimits = [
    { domain = "@gaming"; item = "nofile"; type = "hard"; value = "524288"; }
    { domain = "@gaming"; item = "nofile"; type = "soft"; value = "524288"; }
  ];
}
