{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    pavucontrol
  ];

  sound.enable = true;

  security.rtkit.enable = true;

  services.pipewire.enable = true;
  services.pipewire.wireplumber.enable = true;
  services.pipewire.alsa.enable = true;
  services.pipewire.alsa.support32Bit = true;
  services.pipewire.jack.enable = true;
  services.pipewire.pulse.enable = true;
}
