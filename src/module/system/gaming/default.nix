{ pkgs
, ...
}:

# TODO: build lutris packages here

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
