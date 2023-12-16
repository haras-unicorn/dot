{ pkgs
  # , self
, ...
}:

# FIXME: build lutris packages from yml here with `lutris --install`
# TODO: fix clashing nofile limits

# NOTE: https://github.com/lutris/docs/blob/master/HowToEsync.md

{
  # imports = [
  #   "${self}/src/module/system/nix-ld"
  # ];

  environment.systemPackages = with pkgs; [
    wineWowPackages.waylandFull
    virglrenderer
    win-virtio
    lutris
    retroarch
    cartridges
    winetricks
    protontricks

    # NOTE: common game dependencies
    mono
    gnome.zenity
    fuse
  ];

  programs.steam.enable = true;

  users.groups.gaming = { };

  security.pam.loginLimits = [
    { domain = "@gaming"; item = "nofile"; type = "hard"; value = "524288"; }
    { domain = "@gaming"; item = "nofile"; type = "soft"; value = "524288"; }
  ];
}
