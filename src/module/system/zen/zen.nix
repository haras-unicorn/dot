{ pkgs, ... }:

{
  boot.kernelPackages = pkgs.linuxPackages_zen;
  services.ananicy.enable = true;
  services.earlyoom.enable = true;

  environment.systemPackages = with pkgs; [
    helix
    git
  ];
}
