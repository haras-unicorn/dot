{ pkgs
, nixos-wsl
, ...
}:

{
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = "experimental-features = nix-command flakes";
  nixpkgs.config = import ../../assets/.config/nixpkgs/config.nix;

  imports = [
    nixos-wsl.nixosModules.wsl
  ];

  wsl.enable = true;
  wsl.startMenuLaunchers = true;
  wsl.defaultUser = "nixos";

  environment.systemPackages = with pkgs; [
    vim
    git
    man-pages
    man-pages-posix
    nushell
  ];

  users.users.nixos.shell = pkgs.nushell;

  system.stateVersion = "23.11";
}
