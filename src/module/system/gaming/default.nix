{ pkgs
, config
, ...
}:

# TODO: retroarch and cartridges

{
  environment.systemPackages = with pkgs; [
    wineWowPackages.stable
    lutris
    virglrenderer
    win-virtio
  ];

  programs.steam.enable = true;
}
