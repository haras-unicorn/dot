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
    winetricks
    protontricks
  ];

  programs.steam.enable = true;
}
