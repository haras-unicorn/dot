{ pkgs
, ...
}:

{
  environment.systemPackages = with pkgs; [
    wineWowPackages.stable
    virglrenderer
    win-virtio
    lutris
    retroarch
    cartridges
  ];

  programs.steam.enable = true;
}
