{ inputs, ... }:

{
  machines.nixosModules.sound =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      user = config.dot.user.user;

      hardware = config.dot.hardware;
    in
    {
      imports = [ inputs.musnix.nixosModules.musnix ];

      config = lib.mkIf hardware.sound {
        services.pulseaudio.package = pkgs.pulseaudioFull;

        services.pipewire.enable = true;
        services.pipewire.wireplumber.enable = true;
        services.pipewire.alsa.enable = true;
        services.pipewire.alsa.support32Bit = true;
        services.pipewire.jack.enable = true;
        services.pipewire.pulse.enable = true;

        security.rtkit.enable = true;

        users.users.${user}.extraGroups = [
          "audio"
        ];
        musnix.enable = true;
      };
    };

  machines.homeModules.sound =
    {
      pkgs,
      lib,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf hardware.gaming {
      dot.desktop.windowrules = [
        {
          rule = "float";
          selector = "class";
          arg = "com.saivert.pwvucontrol";
        }
      ];

      dot.desktop.volume = "${pkgs.pwvucontrol}/bin/pwvucontrol";

      home.packages = [
        pkgs.pwvucontrol
        pkgs.crosspipe
      ];
    };
}
