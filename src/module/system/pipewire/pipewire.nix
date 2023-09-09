{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    pavucontrol
    playerctl
  ];

  security.rtkit.enable = true;
  services.pipewire.enable = true;
  services.pipewire.wireplumber.enable = true;
  services.pipewire.alsa.enable = true;
  services.pipewire.jack.enable = true;
  services.pipewire.pulse.enable = true;
}
