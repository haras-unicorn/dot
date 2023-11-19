{ pkgs
, ...
}:

# TODO: build lutris packages from yml here with `lutris --install`

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
  ];

  programs.steam.enable = true;


  users.groups.gaming = { };
  security.pam.loginLimits = [
    {
      domain = "@gaming";
      item = "nofile";
      type = "hard";
      value = "524288";
    }
  ];
}
