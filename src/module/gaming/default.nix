{ pkgs
  # , self
, ...
}:

# TODO: lutris packages

{
  system = {
    programs.steam.enable = true;
    programs.steam.extest.enable = true;
    programs.steam.protontricks.enable = true;
    programs.steam.extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];

    programs.gamemode.enable = true;
  };
}
