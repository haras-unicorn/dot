{ pkgs
, ...
}:

{
  programs.nix-ld.enable = true;

  environment.systemPackages = with pkgs; [
    nix-index
    steam-run
  ];
}
