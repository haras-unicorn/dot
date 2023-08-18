{ pkgs
, nixos-wsl 
, ... 
}:

{
  imports = [
    nixos-wsl.nixosModules.wsl
  ];

  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
    defaultUser = "nixos";
    startMenuLaunchers = true;
  };

  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  environment.systemPackages = with pkgs; [
    vim
    git
  ];

  system.stateVersion = "23.05";
}
