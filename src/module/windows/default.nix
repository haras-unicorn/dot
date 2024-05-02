{ pkgs, ... }:

{
  system = {
    environment.systemPackages = with pkgs; [
      ntfs3g
      woeusb
    ];
  };
}
