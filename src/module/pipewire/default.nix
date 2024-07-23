{ pkgs, ... }:

# TODO: fix screen capture from wayland 
# TODO: check out the systemPackages
# TODO: packages in user

{
  system = {
    environment.systemPackages = with pkgs; [
      pavucontrol
      pwvucontrol
      jamesdsp
      sonobus
    ];

    security.rtkit.enable = true;

    services.pipewire.enable = true;
    services.pipewire.wireplumber.enable = true;
    services.pipewire.alsa.enable = true;
    services.pipewire.alsa.support32Bit = true;
    services.pipewire.jack.enable = true;
    services.pipewire.pulse.enable = true;

    programs.dconf.enable = true;
  };

  home = {
    shared = {
      home.packages = with pkgs; [
        easyeffects
      ];

      services.easyeffects.enable = true;
      services.easyeffects.preset = "speakers";
    };
  };
}
